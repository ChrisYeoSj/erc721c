// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-standards/src/programmable-royalties/BasicRoyalties.sol";
import "@limitbreak/creator-token-standards/src/erc721c/ERC721C.sol";
import "@limitbreak/creator-token-standards/src/access/OwnableBasic.sol";

contract TestCollection is OwnableBasic, ERC721C, BasicRoyalties {

    uint256 private _tokenIdCounter;
    uint256 public MAX_SUPPLY = 10000;

    mapping(uint256 => uint256) private tokenMatrix;

    uint256 public mintPrice = 25000000000000000;

    error InsufficientValueSent();
    error NoMoreTokensLeft();

    constructor(
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_
        ) 
        ERC721OpenZeppelin("TestCollection", "TC") 
        BasicRoyalties(royaltyReceiver_, royaltyFeeNumerator_)
        {
    }

    function ownerMint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function publicMint() payable external {
        if (msg.value != mintPrice)
            revert InsufficientValueSent();

        if ((availableTokenCount() - 1) > 0)
            revert NoMoreTokensLeft();

        _safeMint(msg.sender, nextToken());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://my.nft.com/mycollection/metadata/";
    }


    function availableTokenCount() public view returns (uint256) {
        return MAX_SUPPLY - tokenCount();
    }

    function nextToken() internal returns (uint256) {
        uint256 maxIndex = MAX_SUPPLY - tokenCount();
        uint256 random = uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.prevrandao,
                block.gaslimit,
                block.timestamp
            )
        )) % maxIndex;

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        // Increment counts
        _tokenIdCounter += 1;

        return value;
    }

    function tokenCount() public view returns (uint256) {
        return _tokenIdCounter;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721C, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}