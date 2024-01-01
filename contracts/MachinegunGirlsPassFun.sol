// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './PassRenderer.sol';
import './strings.sol';

contract MachinegunGirlsPassFun is
    ERC721A,
    Ownable,
    Pausable,
    AccessControl
{
    // Librarys
    using Strings for uint256;

    // Error functions
    error CallerIsNotUser(address);
    error InsufficientBalance(uint256);
    error NotMinted();
    error NotTokenOwner(uint256, address);
    error OverNameLength(string);
    error ReachedMintAmount();
    error RestrictTransfer();
    error RestrictApprove();

    // Struct for Owners Token
    struct TokenData {
        uint128 userMintedAmount;
        uint128 tokenId;
    }

    // Roles
    bytes32 public constant ADMIN  = keccak256('ADMIN');

    // Mint Parameters
    uint256 public costForMint = 10000000000000000000;
    mapping(address => TokenData) public _tokenData;
    mapping(uint256 => string) public userPassName;

    // Addresses
    address payable public withdrawAddress = payable(0xF2b12AAa4410928eB8C1a61C0a7BB0447b930303);

    PassRenderer public renderer;

    constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN, _msgSender());

        _pause();
    }


    /**
     * Setter functions
     */
    function setCostForMint(uint256 _cost)
        external
        onlyRole(ADMIN)
    {
        costForMint = _cost;
    }

    function setWithdrawAddress(address payable value)
        public
        onlyRole(ADMIN)
    {
        withdrawAddress = value;
    }

    function setRenderer(PassRenderer _renderer)
        external
        onlyRole(ADMIN)
    {
        renderer = _renderer;
    }

    function changePassName(string calldata _passName, uint256 _tokenId)
        external
        onlyRole(ADMIN)
    {
        if (bytes(_passName).length > 20) revert OverNameLength(_passName);

        userPassName[_tokenId] = _passName;
    }


    /**
     * Getter functions
     */
    function getAllMembersName()
        external
        view
        returns (string[] memory)
    {
        uint256 supply = totalSupply();

        if (supply <= 0) revert NotMinted();

        string[] memory allMembersName = new string[](supply);

        for(uint256 i=1; i<=supply; i++) {
            allMembersName[i-1] = userPassName[i];
        }

        return allMembersName;
    }


    /**
     * Pause / Unpause
     */
    function pause()
        external
        onlyRole(ADMIN)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole(ADMIN)
    {
        _unpause();
    }


    /**
     * Standard functions
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            string(
                abi.encodePacked(
                    'data:application/json;,',
                    '{"name": "MGP FUN - ',
                    userPassName[tokenId],
                    '","image": "data:image/svg+xml;base64,',
                    renderer.buildImage(tokenId, userPassName[tokenId]),
                    '","description": "',
                    userPassName[tokenId],
                    ' is certified member of MACNINEGUN GIRLS PASS FUN. When get lost, go for the fun way...",',
                    '"attributes": [{',
                    '"trait_type": "PASS TYPE",',
                    '"value": "FUN"',
                    '}]}'
                )
            );
    }

    function mint(string calldata passName)
        external
        payable
        whenNotPaused
    {
        if (tx.origin != msg.sender) revert CallerIsNotUser(msg.sender);
        if (costForMint > msg.value) revert InsufficientBalance(msg.value);
        if (bytes(passName).length > 20) revert OverNameLength(passName);
        if (_tokenData[msg.sender].userMintedAmount > 0) revert ReachedMintAmount();

        userPassName[_nextTokenId()] = passName;

        _mint(msg.sender, 1);
    }

    function airDrop(address to, string calldata passName)
        external
        onlyRole(ADMIN)
    {
        if (bytes(passName).length > 20) revert OverNameLength(passName);
        if (_tokenData[to].userMintedAmount > 0) revert ReachedMintAmount();

        userPassName[_nextTokenId()] = passName;

        _mint(to, 1);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return 1;
    }

    function currentIndex()
        external
        view
        returns (uint256)
    {
        return _nextTokenId();
    }

    function withdraw()
        public
        payable
        onlyRole(ADMIN)
    {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    /**
     * Restrict approve and transfer
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override
    {
        if (from != address(0) && to != address(0x000000000000000000000000000000000000dEaD)) {
            revert RestrictTransfer();
        }

        _tokenData[to].userMintedAmount++;
        _tokenData[to].tokenId = uint128(startTokenId);

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (true) revert RestrictApprove();
        super.setApprovalForAll(operator, approved);
    }
    
    function approve(address to, uint256 tokenId)
        public
        payable
        virtual
        override
    {
        if (true) revert RestrictApprove();
        super.approve(to, tokenId);
    }
}