// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract Mayor {
    
    // Structs, events, and modifiers
    
    // Store refund data
    struct Refund {
        uint soul;
        bool doblon;
    }
    
    // Data to manage the confirmation
    struct Conditions {
        uint32 quorum;
        uint32 envelopes_casted;
        uint32 envelopes_opened;
    }
    
    event NewMayor(address _candidate);
    event Sayonara(address _escrow);
    event EnvelopeCast(address _voter);
    event EnvelopeOpen(address _voter, uint _soul, bool _doblon);
    
    // Someone can vote as long as the quorum is not reached
    modifier canVote() {
        require(voting_condition.envelopes_casted < voting_condition.quorum, "Cannot vote now, voting quorum has been reached");
        _;   
    }
    
    // Envelopes can be opened only after receiving the quorum
    modifier canOpen() {
        require(voting_condition.envelopes_casted == voting_condition.quorum, "Cannot open an envelope, voting quorum not reached yet");
        _;
    }
    
    // The outcome of the confirmation can be computed as soon as all the casted envelopes have been opened
    modifier canCheckOutcome() {
        require(voting_condition.envelopes_opened == voting_condition.quorum, "Cannot check the winner, need to open all the sent envelopes");
        _;
    }
    
    // State attributes
    
    // Initialization variables
    address payable public candidate;
    address payable public escrow;
    
    // Voting phase variables
    mapping(address => bytes32) envelopes;
    //****************************************
    // keeping track of who already opened his envelope
    mapping(address => bool) opened_envelopes;

    //***********************************************

    Conditions voting_condition;

    uint public naySoul;
    uint public yaySoul;

    // Refund phase variables
    mapping(address => Refund) souls;
    address payable[] voters;

    //***********************************************
    // the public keyword has been removed from the constructor
    // since it generates a warning message
    //***********************************************

    /// @notice The constructor only initializes internal variables
    /// @param _candidate (address) The address of the mayor candidate
    /// @param _escrow (address) The address of the escrow account
    /// @param _quorum (address) The number of voters required to finalize the confirmation
    constructor(address payable _candidate, address payable _escrow, uint32 _quorum) {
        candidate = _candidate;
        escrow = _escrow;
        voting_condition = Conditions({quorum: _quorum, envelopes_casted: 0, envelopes_opened: 0});
    }


    /// @notice Store a received voting envelope
    /// @param _envelope The envelope represented as the keccak256 hash of (sigil, doblon, soul) 
    function cast_envelope(bytes32 _envelope) canVote public {
        
        // 0x0 means that is the first envelope caste from this sender
        if(envelopes[msg.sender] == 0x0) // => NEW, update on 17/05/2021
            voting_condition.envelopes_casted++;

        envelopes[msg.sender] = _envelope;
        emit EnvelopeCast(msg.sender);
    }
    
    
    /// @notice Open an envelope and store the vote information
    /// @param _sigil (uint) The secret sigil of a voter
    /// @param _doblon (bool) The voting preference
    /// @dev The soul is sent as crypto
    /// @dev Need to recompute the hash to validate the envelope previously casted
    function open_envelope(uint _sigil, bool _doblon) canOpen public payable {
        
        // TODO Complete this function

            // emit EnvelopeOpen() event at the end

        require(envelopes[msg.sender] != 0x0, "The sender has not casted any votes");
        // ******************************************************
        // check that the envelope has not opened yet
        require(opened_envelopes[msg.sender] == false, "The sender has already opened his envelope");
        // ****************************************************
        
        bytes32 _casted_envelope = envelopes[msg.sender];
        bytes32 _sent_envelope = 0x0;
        // ...
        // ***************************************************
        _sent_envelope = keccak256(abi.encode(_sigil, _doblon, msg.value));
        // ***************************************************

        require(_casted_envelope == _sent_envelope, "Sent envelope does not correspond to the one casted");

        // ...
        // ***************************************************
        
        // set the opened envelope to true
        opened_envelopes[msg.sender] = true;
        // increment # of envelopes opened
        voting_condition.envelopes_opened++;

        // instantiate a refund
        Refund memory refund;
        refund.doblon = _doblon;
        refund.soul = msg.value;
        // set the refund in souls
        souls[msg.sender] = refund;
        voters.push(payable(msg.sender));

        // increment votes counters and souls counter
        if (_doblon){
            yaySoul = yaySoul + msg.value;
        }else{
            naySoul = naySoul + msg.value;
        }
            
        //emit event
        emit EnvelopeOpen(msg.sender, msg.value, _doblon);

        // ***************************************************
    }
    
    
    /// @notice Either confirm or kick out the candidate. Refund the electors who voted for the losing outcome
    function mayor_or_sayonara() canCheckOutcome public {

        // TODO Complete this function
            
            // emit the NewMayor() event if the candidate is confirmed as mayor
            // emit the Sayonara() event if the candidate is NOT confirmed as mayor 

        // *****************************************************
        if (yaySoul > naySoul) {
            // CONFIRM CANDIDATE
            //emit event
            emit NewMayor(candidate);
            //go through all the voters and refund ones who lose
            uint n_voters = voters.length;
            for (uint i=0; i<n_voters; i++){
                //if doblon is False 
                if (!(souls[voters[i]].doblon)){
                    voters[i].transfer(souls[voters[i]].soul);
                }
            }            
            //transfer money to candidate
            candidate.transfer(yaySoul);
        }else{
            //KICK OFF CANDIDATE
            //emit sayonara event
            emit Sayonara(escrow);
            //go through all the voters and refund ones who lose
            uint n_voters = voters.length;
            for (uint i=0; i<n_voters; i++){
                //if doblon is True 
                if (souls[voters[i]].doblon){
                    voters[i].transfer(souls[voters[i]].soul);
                }
            }
            //transferm money to escrow
            escrow.transfer(naySoul);
        }       

        // *****************************************************       
    }
 
 
    /// @notice Compute a voting envelope
    /// @param _sigil (uint) The secret sigil of a voter
    /// @param _doblon (bool) The voting preference
    /// @param _soul (uint) The soul associated to the vote
    function compute_envelope(uint _sigil, bool _doblon, uint _soul) public pure returns(bytes32) {
        return keccak256(abi.encode(_sigil, _doblon, _soul));
    }
    
}
