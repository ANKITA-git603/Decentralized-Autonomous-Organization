// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DAO {
    // State variables
    address public owner;
    uint256 public proposalCount;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant PROPOSAL_THRESHOLD = 100; // Minimum tokens to create proposal
    
    // Governance token balances
    mapping(address => uint256) public tokenBalance;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 deadline;
        bool executed;
        bool exists;
    }
    
    mapping(uint256 => Proposal) public proposals;
    
    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event TokensDeposited(address indexed user, uint256 amount);
    
    modifier onlyTokenHolder() {
        require(tokenBalance[msg.sender] > 0, "Must hold governance tokens");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // Give initial tokens to contract deployer
        tokenBalance[msg.sender] = 1000;
    }
    
    /**
     * @dev Core Function 1: Create a new proposal
     * @param _description Description of the proposal
     */
    function createProposal(string memory _description) external onlyTokenHolder {
        require(tokenBalance[msg.sender] >= PROPOSAL_THRESHOLD, "Insufficient tokens to create proposal");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        proposalCount++;
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: _description,
            forVotes: 0,
            againstVotes: 0,
            deadline: block.timestamp + VOTING_PERIOD,
            executed: false,
            exists: true
        });
        
        emit ProposalCreated(proposalCount, msg.sender, _description);
    }
    
    /**
     * @dev Core Function 2: Vote on a proposal
     * @param _proposalId ID of the proposal to vote on
     * @param _support True for yes, false for no
     */
    function vote(uint256 _proposalId, bool _support) external onlyTokenHolder proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!hasVoted[msg.sender][_proposalId], "Already voted on this proposal");
        
        uint256 voterTokens = tokenBalance[msg.sender];
        hasVoted[msg.sender][_proposalId] = true;
        
        if (_support) {
            proposal.forVotes += voterTokens;
        } else {
            proposal.againstVotes += voterTokens;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, voterTokens);
    }
    
    /**
     * @dev Core Function 3: Execute a proposal if it has passed
     * @param _proposalId ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp > proposal.deadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");
        
        proposal.executed = true;
        
        // In a real DAO, this would execute the actual proposal logic
        // For this example, we just mark it as executed
        
        emit ProposalExecuted(_proposalId);
    }
    
    // Additional helper functions
    
    /**
     * @dev Deposit governance tokens (simplified - in reality would be ERC20 transfer)
     */
    function depositTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        tokenBalance[msg.sender] += _amount;
        emit TokensDeposited(msg.sender, _amount);
    }
    
    /**
     * @dev Get proposal details
     */
    function getProposal(uint256 _proposalId) external view proposalExists(_proposalId) 
        returns (
            uint256 id,
            address proposer,
            string memory description,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 deadline,
            bool executed
        ) 
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.deadline,
            proposal.executed
        );
    }
    
    /**
     * @dev Check if voting is active for a proposal
     */
    function isVotingActive(uint256 _proposalId) external view proposalExists(_proposalId) returns (bool) {
        return block.timestamp <= proposals[_proposalId].deadline;
    }
    
    /**
     * @dev Get user's voting power
     */
    function getVotingPower(address _user) external view returns (uint256) {
        return tokenBalance[_user];
    }
}
