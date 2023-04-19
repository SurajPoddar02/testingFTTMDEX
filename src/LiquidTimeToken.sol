// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "./interfaces/ILiquidTimeToken.sol";

contract LiquidTimeToken is
    ILiquidTimeToken,
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    Ownable,
    ERC20Permit,
    ReentrancyGuard,
    Pausable
{
    uint256 public constant MONTHLY_SUPPLY = 1000; // maximum supply of tokens that can be minted per month
    uint256 public lastMintTimestamp; // timestamp of the last time tokens were minted
    uint256 public mintedThisMonth; // amount of tokens already minted this month
    uint256 public totalAmountMinted;
    address DAOAddress;
    bool isCalendarFrozen;

    WorkingHour[] public workingHours;

    mapping(address => uint16) public NbOfInteractionsPerClient;
    mapping(address => mapping(uint16 => ClientRating)) internal ratingPerClientInteraction;

    /** Modifier **/
    modifier validateWorkingHour(
        uint256 _day,
        uint256 _startHour,
        uint256 _endHour
    ) {
        require(_day >= 0 && _day <= 6, "Invalid day");
        require(_startHour >= 0 && _startHour <= 24, "Invalid startHour");
        require(_endHour >= 0 && _endHour <= 24, "Invalid endHour");
        require(_startHour < _endHour, "Invalid hours");
        _;
    }

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _associatedDAOAddress
    ) ERC20(_tokenName, _tokenSymbol) ERC20Permit(_tokenName) {
        require(_associatedDAOAddress != address(0x0), "ERR: Invalid dao address");
        lastMintTimestamp = block.timestamp;
        DAOAddress = _associatedDAOAddress;
    }

    /** User actions **/

    /**
     * @dev Mints new tokens and assigns them to the DAOAddress.
     * Can only be called by the contract owner and must not exceed the allowed MONTHLY_SUPPLY.
     *
     * @param _amount The number of tokens to be minted.
     */
    function mint(uint256 _amount) external onlyOwner whenNotPaused nonReentrant {
        require(_amount != 0, "ERR: Invalid amount");
        uint256 currentTimeStamp = block.timestamp;

        // Ensure that the total amount to be minted in the current month does not exceed the allowed MONTHLY_SUPPLY
        require(mintedThisMonth + _amount <= MONTHLY_SUPPLY, "ERR: Exceeds monthly supply");

        // Check if it has been a new month since the last mint
        if (currentTimeStamp - lastMintTimestamp >= 30 days) {
            // Reset the minted amount for the new month
            mintedThisMonth = _amount;
        } else {
            // Increase the minted amount for the current month
            mintedThisMonth += _amount;
        }

        // Update the total amount of tokens minted
        totalAmountMinted += _amount;

        // Update the timestamp of the last mint
        lastMintTimestamp = currentTimeStamp;

        // Mint the new tokens and assign them to the DAOAddress
        _mint(DAOAddress, _amount);

        emit LogMint(DAOAddress, _amount, currentTimeStamp);
    }

    function createClientRating() external whenNotPaused nonReentrant {
        uint16 interactionCount = NbOfInteractionsPerClient[msg.sender];
        ClientRating memory newClientRating = ClientRating({
            NbOfSlotsBooked: interactionCount,
            rating: 0,
            isRatingSet: false
        });
        ratingPerClientInteraction[msg.sender][interactionCount] = newClientRating;
        NbOfInteractionsPerClient[msg.sender]++;
    }

    function ownerRateInteraction(
        address _client,
        uint16 _interactionId,
        uint8 _ratingValue
    ) external onlyOwner whenNotPaused {
        require(_client != address(0x0), "ERR: Invalid Client");
        require(_ratingValue >= 1 && _ratingValue <= 5, "ERR: Invalid Rating");
        require(!ratingPerClientInteraction[_client][_interactionId].isRatingSet, "Rating already set");
        ratingPerClientInteraction[_client][_interactionId].rating = _ratingValue;
        ratingPerClientInteraction[_client][_interactionId].isRatingSet = true;
        emit LogOwnerRateInteraction(_client, _interactionId, _ratingValue);
    }

    function addWorkingHour(
        uint256 _day,
        uint256 _startHour,
        uint256 _endHour
    ) external onlyOwner whenNotPaused nonReentrant validateWorkingHour(_day, _startHour, _endHour) {
        require(!isCalendarFrozen, "Calendar is frozen");
        require(_startHour != 0 && _endHour != 0, "ERR: Invalid start end time");
        WorkingHour memory hour = WorkingHour({day: _day, startHour: _startHour, endHour: _endHour});
        workingHours.push(hour);
        emit LogAddWorkingHour(_day, _startHour, _endHour);
    }

    function freezeCalendar() external onlyOwner whenNotPaused {
        require(workingHours.length == 7, "Not all working hours are defined");

        // Check if all days from 0 to 6 are correctly listed in workingHours
        bool[7] memory daysPresent;
        for (uint256 i = 0; i < workingHours.length; i++) {
            daysPresent[workingHours[i].day] = true;
        }

        for (uint256 j = 0; j < 7; j++) {
            require(daysPresent[j], "Not all days are correctly listed in working hours");
        }
        isCalendarFrozen = true;
    }

    /** Support **/

    /// @notice Triggers stopped state.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Returns to normal state.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }

    /** Getter **/
    function getClientRating(address _client, uint16 _interactionId) external view returns (ClientRating memory) {
        return ratingPerClientInteraction[_client][_interactionId];
    }

    /**
     * @dev Returns an array of days, start hours, and end hours of the working hours in a week.
     * The length of each returned array will be equal to the number of working hour entries.
     *
     * @return daysArray An array of days in the week with working hours.
     * @return startHours An array of start hours corresponding to the days in the daysArray.
     * @return endHours An array of end hours corresponding to the days in the daysArray.
     */
    function getWorkingHoursWeek()
        external
        view
        returns (uint256[] memory daysArray, uint256[] memory startHours, uint256[] memory endHours)
    {
        // Initialize arrays for days, start hours, and end hours with the length of workingHours array
        daysArray = new uint256[](workingHours.length);
        startHours = new uint256[](workingHours.length);
        endHours = new uint256[](workingHours.length);

        // Iterate through the workingHours array
        for (uint256 i = 0; i < workingHours.length; i++) {
            // Retrieve the WorkingHour struct from the workingHours array
            WorkingHour memory hour = workingHours[i];

            // Store the day, start hour, and end hour in their respective arrays
            daysArray[i] = hour.day;
            startHours[i] = hour.startHour;
            endHours[i] = hour.endHour;
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}