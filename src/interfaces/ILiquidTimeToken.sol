// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ILiquidTimeToken is IERC20 {
    /** Structs **/
    struct ClientRating {
        uint16 NbOfSlotsBooked;
        uint8 rating;
        bool isRatingSet;
    }

    struct WorkingHour {
        uint256 day;
        uint256 startHour;
        uint256 endHour;
    }

    /** Events **/
    event LogMint(address _dao, uint256 indexed _amount, uint256 indexed _time);

    event LogOwnerRateInteraction(address indexed _client, uint16 indexed _interactionId, uint8 _ratingValue);

    event LogAddWorkingHour(uint256 indexed _day, uint256 _startHour, uint256 _endHour);

    /** Functions **/
    function mint(uint256 _amount) external;

    function createClientRating() external;

    function ownerRateInteraction(address _client, uint16 _interactionId, uint8 _ratingValue) external;

    function addWorkingHour(uint256 _day, uint256 _startHour, uint256 _endHour) external;

    function freezeCalendar() external;

    function getClientRating(address _client, uint16 _interactionId) external view returns (ClientRating memory);

    function getWorkingHoursWeek()
        external
        view
        returns (uint256[] memory _daysArray, uint256[] memory _startHours, uint256[] memory _endHours);

    function snapshot() external;
}