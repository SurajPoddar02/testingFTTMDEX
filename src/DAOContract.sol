// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./FTTMDEX.sol";

contract DAO {
    // Define the proposal struct
    struct Proposal {
        address proposer;
        uint256 feeInWei;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTime;
        bool executed;
    }

    IERC20 public UFTTToken;
    uint256 public transactionFee;
    mapping(address => uint256) public balances;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public votingDuration;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event NewProposal(uint256 indexed proposalId, uint256 feeInWei, uint256 endTime);
    event Vote(uint256 indexed proposalId, address indexed voter, bool inSupport, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId, uint256 feeInWei);

    constructor(address _UFTTtoken, uint256 _votingDuration) {
        UFTTToken = IERC20(_UFTTtoken);
        votingDuration = _votingDuration;
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        UFTTToken.transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        UFTTToken.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function createProposal(uint256 _feeInWei) external {
        uint256 endTime = block.timestamp + votingDuration;
        proposals[proposalCount] = Proposal(msg.sender, _feeInWei, 0, 0, endTime, false);
        emit NewProposal(proposalCount, _feeInWei, endTime);
        proposalCount++;
    }

    function FTTMOwnerSendTokensOnPrimaryMarket(IERC20 FTTMToken, uint256 amount, FTTMDEX dex) external {
        Ownable ownableToken = Ownable(address(FTTMToken));
        require(msg.sender == ownableToken.owner(), "The msg.sender should be the token owner");
        dex.provideLiquidity(amount, 0);
    }

    function vote(uint256 _proposalId, bool _inSupport) external {
        require(_proposalId < proposalCount, "Invalid proposal ID");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended");
        require(balances[msg.sender] > 0, "Insufficient tokens for voting");

        Proposal storage proposal = proposals[_proposalId];

        if (_inSupport) {
            proposal.yesVotes += balances[msg.sender];
        } else {
            proposal.noVotes += balances[msg.sender];
        }

        emit Vote(_proposalId, msg.sender, _inSupport, balances[msg.sender]);
    }

    function executeProposal(uint256 _proposalId) external {
        require(_proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period is still ongoing");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.yesVotes > proposal.noVotes) {
            transactionFee = proposal.feeInWei;
        }
    }
}