pragma solidity ^0.5.16;

contract OwnershipMain {
    
	address payable public govtAddress = 0x02F02Cd3C765AbFEF1d7d2610817460C7B61c2EC;
	uint uniqueLandCode = 1;
	
	modifier onlyOwner() {
	    require(msg.sender == govtAddress);
	    _;
	}

	struct Land {
		uint _uniqueLandCode;
		uint costPrice;
		uint sellingPrice;
		string area;
		string saleStatus;
		address[] history;
	}

	mapping (uint => address payable) landToOwner;
	mapping (address => uint) ownerLandCount;
	
	Land[] lands;  
	
	event Purchased (address indexed _buyer, uint _amount);
	event Transferred (address indexed _to, uint _uniqueLandCode);
	event NewLandAdded (uint costPrice, uint sellingPrice, string indexed area);

	// Functions to register a new land into the record (only government can do that from a specific address)
	function newLandRegistered (uint costPrice, uint sellingPrice, string calldata area) external onlyOwner { 
		Land memory land = Land(uniqueLandCode, costPrice, sellingPrice, area, "Active", new address[](0));
		lands.push(land);
		lands[(lands.length) - 1].history.push(msg.sender);
		landToOwner[uniqueLandCode] = msg.sender;
		ownerLandCount[msg.sender]++;
		uniqueLandCode++;
		emit NewLandAdded(costPrice, sellingPrice, area);
	}

	// Function to get all the lands that an owner has
	function getUniqueCodesOfLandsBySpecificOwner(address _ownerAddress) private view returns(uint[] memory) {
		uint[] memory result = new uint[](ownerLandCount[_ownerAddress]); 
		uint counter = 0;
		for (uint i = 1; i <= lands.length; i++) {
			if (landToOwner[i] == _ownerAddress) {
				result[counter] = i;
				counter++;
			}
		}
		return result;
	}
	
	// Function to get all the lands that are on sale of a specific owner
	function landsOnSaleForSpecificArea(string calldata _area) external view returns(uint[] memory) {
	    uint[] memory result = new uint[](lands.length);
	    uint counter = 0;
		for (uint i = 1; i <= lands.length; i++) {
		    if (
                (keccak256(abi.encodePacked(lands[i - 1].saleStatus)) ==keccak256(abi.encodePacked("Active"))) && 
                (keccak256(abi.encodePacked(lands[i - 1].area)) == keccak256(abi.encodePacked(_area)))) {
				result[counter] = i;
				counter++;
			}
		}
		
		uint[] memory result2 = new uint[](counter);
		for (uint j = 0; j < result2.length; j++) {
		    result2[j] = result[j];
		}
		return result2;
	}

	// Function to get details of a specific owner using his _ownerId
	function specificOwnerDetails() external view returns (address, uint, uint[] memory) {
		if (ownerLandCount[msg.sender] >= 0) {
		    return (msg.sender, ownerLandCount[msg.sender], getUniqueCodesOfLandsBySpecificOwner(msg.sender));
		}
		revert ("The owner does not exist");
	}
	
	// Function to get details of a specific land using its _uniqueLandCode
	function specificLandDetails(uint _uniqueLandCode) external view returns (uint, uint, uint, string memory, string memory, address[] memory) {
		if (_uniqueLandCode >= uniqueLandCode) {
		    revert ("Wrong unique land code");
		}
		return (
			    lands[_uniqueLandCode - 1]._uniqueLandCode, 
			    lands[_uniqueLandCode - 1].costPrice, 
			    lands[_uniqueLandCode - 1].sellingPrice, 
			    lands[_uniqueLandCode - 1].area, 
			    lands[_uniqueLandCode - 1].saleStatus, 
			    lands[_uniqueLandCode - 1].history
	    );
	}

	// Function to transfer ownership of a land piece to another user (sale without ether)
	function transferFrom(address _from, address payable _to, uint256 _uniqueLandCode) external {
		if (landToOwner[_uniqueLandCode] != msg.sender) {
		    revert ("Not the owner");
		}
		_transfer(_from, _to, _uniqueLandCode);
		emit Transferred(_to, _uniqueLandCode);
	}

	function _transfer(address _from, address payable _to, uint256 _uniqueLandCode) private {
		ownerLandCount[_to]++;
		ownerLandCount[_from]--;
		lands[_uniqueLandCode - 1].saleStatus = "Inactive";
		landToOwner[_uniqueLandCode] = _to;
		lands[_uniqueLandCode - 1].history.push(_to);
	} 
	
	// Function to change the on sale status of a land piece and its selling price
	function onSale(uint _uniqueLandCode, uint sellingPrice) external {
	    if (landToOwner[_uniqueLandCode] != msg.sender) {
			revert ("Not the owner");
		}
		lands[_uniqueLandCode - 1].sellingPrice = sellingPrice;
		lands[_uniqueLandCode - 1].saleStatus = "Active";
	}
	
	// Function to sell a piece of land (sale with ether)
	function onPurchase(uint _uniqueLandCode) external payable {
	    if (keccak256(abi.encodePacked(lands[_uniqueLandCode - 1].saleStatus)) != keccak256(abi.encodePacked("Active"))) {
			revert ("Land not on sale");
		}
		if (msg.value < lands[_uniqueLandCode - 1].sellingPrice) {
		    revert ("Wrong price value");
		}
		address payable landOwner = landToOwner[_uniqueLandCode];
		bool sent = landOwner.send(msg.value);
        require(sent, "Failed to Purchase");
		_transfer(landToOwner[_uniqueLandCode], msg.sender, _uniqueLandCode);
	}
	
	// Function to withdraw a piece of land from Active sale status
	function cancelSale(uint _uniqueLandCode) external {
	    if (landToOwner[_uniqueLandCode] != msg.sender) {
			revert ("Not the owner");
		}
		lands[_uniqueLandCode - 1].saleStatus = "Inactive";
	}

}