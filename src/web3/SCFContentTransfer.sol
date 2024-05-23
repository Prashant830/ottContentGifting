// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContentSharing {
    // Struct to represent a content item
    struct Content {
        address owner;
        string title;
        string url;
        address oldOwner;
        bool isAvailable; // Flag to indicate if the content is available for sharing
        bool isContentVisible; // New field to indicate if the content is visible
    }
    
    // Mapping to store content tokens and their corresponding details
    mapping(uint256 => Content) public contents;
    
    // Mapping to store the list of content tokens owned by each address
    mapping(address => uint256[]) private ownedContent;

    // Event emitted when content ownership is transferred
    event ContentTransferred(address indexed from, address indexed to, uint256 tokenId);
    // Event emitted when content visibility is updated
    event ContentVisibilityUpdated(uint256 tokenId, bool isContentVisible);
    // Event emitted when Ether is transferred
    event FundsTransferred(address indexed from, address indexed to, uint256 amount);
    
    // Function to create a new content token
    function createContent(uint256 _tokenId, string memory _title, string memory _url) public {
        // Check if the content token already exists
        require(!isContentExist(_tokenId), "Content already exists");
        
        // Create a new content token with `isContentVisible` set to false
        contents[_tokenId] = Content({
            owner: msg.sender,
            title: _title,
            url: _url,
            oldOwner: msg.sender,
            isAvailable: true,
            isContentVisible: false
        });
        
        // Add the token to the creator's list of owned content
        ownedContent[msg.sender].push(_tokenId);
    }
    
    // Function to check if a content token exists
    function isContentExist(uint256 _tokenId) internal view returns (bool) {
        return contents[_tokenId].owner != address(0);
    }

    // Function to check if a recipient address has been banned for policy violations
    function isRecipientBanned(address) internal pure returns (bool) {
        // Implement logic to check if the recipient address has been banned for policy violations
        // If user address does not follow the policy, then return true, else false

        // By default, false for everyone
        return false; // Assuming no policy violation checks are needed in this example
    }

    // Function to transfer ownership of a content token
    function transferContent(address _to, uint256 _tokenId) public {
        // Check if the content token exists
        require(isContentExist(_tokenId), "Content does not exist");
        
        // Check if the sender owns the content
        require(contents[_tokenId].owner == msg.sender, "Only the owner can transfer the content");
        
        // Check if the content is available for sharing
        require(contents[_tokenId].isAvailable, "Content not available for sharing");
        
        // Check if the recipient is a valid Ethereum address
        require(_to != address(0), "Invalid recipient address");

        // Check if the recipient has not been banned for policy violations
        require(!isRecipientBanned(_to), "Recipient address has been banned for policy violations");

        // Transfer ownership of the content token
        address previousOwner = contents[_tokenId].owner;
        contents[_tokenId].owner = _to;
        contents[_tokenId].isAvailable = false; // Mark content as not available for sharing
        
        // Remove the token from the previous owner's list
        uint256[] storage ownerTokens = ownedContent[previousOwner];
        for (uint256 i = 0; i < ownerTokens.length; i++) {
            if (ownerTokens[i] == _tokenId) {
                ownerTokens[i] = ownerTokens[ownerTokens.length - 1];
                ownerTokens.pop();
                break;
            }
        }

        // Add the token to the new owner's list
        ownedContent[_to].push(_tokenId);

        // Emit event
        emit ContentTransferred(msg.sender, _to, _tokenId);
    }
    
    // Function to retrieve content details
    function getContentDetails(uint256 _tokenId) public view returns (string memory, string memory, bool, bool) {
        // Check if the content token exists
        require(isContentExist(_tokenId), "Content does not exist");
        
        // Return content details
        Content memory content = contents[_tokenId];
        return (content.title, content.url, content.isAvailable, content.isContentVisible);
    }

    // Function to retrieve the content details of all tokens owned by a specific account
    function getOwnedContentDetails(address _account) public view returns (Content[] memory) {
        uint256[] storage tokenIds = ownedContent[_account];
        Content[] memory contentDetails = new Content[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            contentDetails[i] = contents[tokenIds[i]];
        }
        
        return contentDetails;
    }

    // Function to transfer Ether from the contract to a specified address
    function transferContentFunds(address payable _toAddress, address _fromAddrss, uint256 _amountInWei) external payable {
       address myAddress = address(this);
        if (myAddress.balance >= _amountInWei) {
            _toAddress.transfer(_amountInWei);
        }        
        // Emit FundsTransferred event
        // emit FundsTransferred(msg.sender, _toAddress, _amountInWei);

        // Update the isContentVisible field to true for all owned content of the recipient
        uint256[] storage tokenIds = ownedContent[_fromAddrss];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            contents[tokenId].isContentVisible = true;

            // Emit ContentVisibilityUpdated event
            emit ContentVisibilityUpdated(tokenId, true);
        }
    }
}
