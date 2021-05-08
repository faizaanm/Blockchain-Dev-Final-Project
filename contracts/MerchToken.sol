pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
Accounts:
(0) 0x110fbc9f146f3bc3427e3dc6d973ee5c32260ce1
(1) 0x45917faf4623c28c65c130cf1e4020eb394560ba
(2) 0x74a4b64575da1ea72c24241f5616a1400d78b154
(3) 0x0d6398ab46a4db7a73a307dff7cb70af302bf645
(4) 0x6184337a11ddbd29aebea04ae4ac048df4ae02c1
(5) 0x1b306fd13ba28d1fec20d240a2536be94f8ac272
(6) 0xe72c4ecc7db69c15c74840d1a103d95b6694b077
(7) 0xbbfa39712c9116f6a6922175497f55a088642425
(8) 0xe02b4bf22b5a46af9a08baf82f6243bf6861ff1e
(9) 0xe3d746565f28df308b72f3f6eb7bdeb122d2505e

Private Keys:
(0) eed1a341a0ed90530a9dde2891921610125778861638c6533501acc4ffd83db9
(1) 2c68d2c186a2f66b35a7fb7fc2a054404936346c2f671ffc8713ace257b3161b
(2) 3ff9018c8b94f7395ce782840be0455aadae1a63c899a5027ba4d88a89cd19b4
(3) e9848962bd6cdbb727f17e9f195930d682a9f430916fa6053f0c8a992efc0a29
(4) 7396f7daca569468e6ee25dde63ba93ed7a63d542e132b0bb5cc61f3cdd4c2dc
(5) ab1d5acad9f2efec8233cf3995dac54b0f25fbb72cb8069362a000b510d82b13
(6) d2c9884aca9b76bde9406828c0c330d18e6dca877506882ab6d57efcd98a0cfb
(7) 6f8ef6e7263a4797a4fb744643b90976415a1271b0f3e7eef7655ecd89013114
(8) 22648f45757c341b717a8f81ba97cfa9a0be94e7123d086998dbb827f5d30818
(9) dea278f104d2352a1ec4f4202883d3ffad0f50a1121071a3ec4893f76a921106

Mnemonic: coil parent climb kick crash flag father wage radar electric shell guess
 */


contract MerchToken is ERC721, Ownable {
    /*** EVENTS ***/
    /// The event emitted (useable by web3) when a token is purchased
    event MerchToken(address indexed buyer, uint256 tokenId);

    /*** CONSTANTS ***/
    uint8 constant NAME_MIN_LENGTH = 1;
    uint8 constant NAME_MAX_LENGTH = 64;
    string constant public merchTypes = "SHIRT,SOCKS,BACKPACK,PANTS,BRICK";
    string constant public tags = "COOL,SICK,SEXY,CRINGE,CLOUTED,INSANE,COZY,SAD,LEGIT,GOBEARS";

    /*** DATA S ***/
    struct MerchInfo {
        uint256 price;
        string name;
        string picture;
        string description;
        uint256 merchType;
        uint256 tag;
        bool forSale;
    }

    //This mapping is from the tokens that exist in the contract to
    //a relevant MerchInfo struct containing the token's properties
    mapping(uint256 => MerchInfo) tokenInfos;

    // The next token id to be issued. Every time a token is minted, index
    // increases by 1.
    uint256 index;

    constructor() public ERC721("Merch Token", "OSKI") {
        // any init code when you deploy the contract would run here

        //initialize contract with no tokens
        index = 0;
    }

    /* Requires the amount of Ether be at least or more of the currentPrice
     * @dev Creates an instance of an token and mints it to the purchaser.
     *
     * the default ERC721 Requires gas to mint, but we modified
     * it to mint for free and have a price set by the user*/
    function mintToken(
        uint256 _price,
        string calldata _name,
        string calldata _picture,
        string calldata _description,
        bool _forSale
    ) external payable {
        bytes memory _nameBytes = bytes(_name);
        require(_price > 0, "Price must be greater than 0");
        require(bytes(_picture).length != 0, "you need a picture");
        require(
            bytes(_description).length != 0,
            "Description should not be null"
        );
        require(_nameBytes.length >= NAME_MIN_LENGTH, "Title is too short");
        require(_nameBytes.length <= NAME_MAX_LENGTH, "Title is too long");

        // ***********TO DO:*************  Generate psedorandom numbers
        // by running blocktimestamp+address -> blackbox hashing function -> determine from last digit of result
        bytes32 hash1 = sha256(abi.encodePacked(block.number, msg.sender));
        bytes32 hash2 = keccak256(abi.encode(hash1));
        uint256 result = uint256(hash2);

        uint256 _merchType = result % 10;
        uint256 _tag = result % 5;

        require(_tag <= 4, "Failed random check, ID too large");
        require(_merchType <= 9, "Failed random check, tagID too large");

        _mint(msg.sender, index);

        tokenInfos[index] = MerchInfo({
            price: _price,
            name: _name,
            picture: _picture,
            description: _description,
            merchType: _merchType,
            tag: _tag,
            forSale: _forSale
        });

        //*****TO:DO****** once a token is minted, tell the contract by changing one variable
        index += 1;

        emit MerchToken(msg.sender, index);
    }

    function buyToken(uint256 _id) external payable {
        require(tokenInfos[_id].price > 0); // ensure token exists
        require(msg.value >= tokenInfos[_id].price); // ensure enough money paid for token
        require(tokenInfos[_id].forSale == true); // ensure for sale

        //pay with eth
        bool sent = payable(ownerOf(_id)).send(msg.value);
        require(sent, "Failed to send Ether");

        //transfer the NFT
        _transfer(ownerOf(_id), msg.sender, _id);
        tokenInfos[_id].forSale = false;
    }

    // Returns the number of tokens issued so far
    function getTokens() public returns (uint256) {
        return index;
    }

    /* @notice Returns all the relevant information about a specific token
     * @param _tokenId The ID of the token of interest */
    function getToken(uint256 _tokenId)
        external
        view
        returns (
            string memory _name,
            string memory _picture,
            string memory _description,
            uint256[3] memory _ints, //price, tag, and type are stored as ints in this array
            bool _forSale
        )
    {
        require(_tokenId < index); // ensure token exists

        _name = tokenInfos[_tokenId].name;
        _picture = tokenInfos[_tokenId].picture;
        _description = tokenInfos[_tokenId].description;

        _ints[0] = (tokenInfos[_tokenId].price);
        _ints[1] = (tokenInfos[_tokenId].merchType);
        _ints[2] = (tokenInfos[_tokenId].tag);

        _forSale = tokenInfos[_tokenId].forSale;
    }

    //******TO DO************
    // Changes the price that must be paid to buy a particular token
    function changePrice(uint256 _tokenId, uint256 _newPrice) public {
        require(_newPrice != 0 && (_tokenId <= index));
        require(ownerOf(_tokenId) == msg.sender);
        tokenInfos[_tokenId].price = _newPrice;
    }

    // Allow a token to be sold
    function listToken(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
        require(!tokenInfos[_tokenId].forSale);
        tokenInfos[_tokenId].forSale = true;
    }

    // Disallow a token to be sold
    function unListToken(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
        require(tokenInfos[_tokenId].forSale);
        tokenInfos[_tokenId].forSale = false;
    }
}
