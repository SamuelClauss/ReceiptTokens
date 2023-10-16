// SPDX-License-Identifier: MIT

// versions >= 0.8.20 are not compatible with the Mumbai Testnet
pragma solidity ^0.8.19;

// to get the contract running on the Mumbai Testnet, it is essential to change the pragma solidities in all the needed files to 0.8.19.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ReceiptToken is ERC721, ERC721Burnable, Ownable {

    //--------------------------Global_Variables-------------------------

    // counter for the NFT tokenId's
    uint256 private _nextTokenId;

    // string for the different CompanyTypes (check constructor for the different Types)
    string[4] public CompanyTypes;

    

    //----------------------------Constructor----------------------------




    constructor(address initialOwner) 
        ERC721("ReceiptToken", "RCT") 
        Ownable(initialOwner)
        {
            CompanyTypes[0] = "Transportation";
            CompanyTypes[1] = "Food";
            CompanyTypes[2] = "Accommondation";
            CompanyTypes[3] = "Entertainment";
        }


    //------------------------------Structs------------------------------


    /**
    @notice stores the Data of the corresponding ReceiptNFT
    @param The date when the transaction of the receipt took place
    @param The price of the transaction.
    @param Any other information that might be of importance.
    */
    struct NFTData {
        uint256 date;
        uint256 price;
        string others; 
    }


    /**
    @notice stores the information of the companies that registered for the ReceiptTokenContract
    @param initialized, helper variable. Is later used in the onlyAuthorized Modifier.
    @param Name of the company.
    @param Location of the company.
    @param The Type of the company (check constructor for the types).
    */
    struct Companies {
        bool initialized;
        string name;
        string location;
        string CompanyType;
    }


    //----------------------------Mappings-------------------------------



    // mapping the NFTData to the corresponding TokenId
    mapping(uint => NFTData) TokenInformation;

    // mapping each TokenId to all the addresses that have owned the token at one point in history (mapping will be important in a second SC)
    mapping(uint => address[]) public addressMap;

    // mapping the address of the registered companies to its corresponding information
    mapping(address => Companies) public RegisteredCompanies;



    //----------------------------Modifier----------------------------


    // making sure that only registered Companies can mint a NFT with this contract
    modifier onlyAuthorized() {

        // checking that the struct is initialized (not the default value)
        // Either the caller is a registered company or the owner himself.
        require(RegisteredCompanies[msg.sender].initialized || msg.sender == Ownable.owner(), "Only registered Companies can call this Function!");
        _;
    }



    //----------------------------Functions----------------------------


    /**
    * @dev Adds new company to the RegisteredCompanies mapping 
    * @param Address of the company
    * @param Name of the company  
    * @param Location of the company 
    * @param Type of the company (check constructor for the types)  
    */
    function RegisterCompany(address _company, string memory _name, string memory _location, uint8 _Type) public onlyOwner {
        Companies memory newCompany = Companies(true, _name, _location, CompanyTypes[_Type]);
        RegisteredCompanies[_company] = newCompany;
    }


    /**
    * @dev Removes Company from the RegisteredCompanies mapping
    * @param company, the address of the company that will be removed
    */
    function RemoveCompany(address _company) public onlyOwner {
        delete RegisteredCompanies[_company];
    }



    /**
    * @dev Helper Function. Mints a NFT, increases the NFT counter by one and returns the actual tokenId. 
    * @param Address to whom the token should be minted 
    * @return The current TokenId
    */
    function safeMint(address _to) private onlyAuthorized returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(_to, tokenId);
        return tokenId;
    } 


    /**
    * @dev Mints an NFT. (safeMint() )  , maps the corresponding data to the newly minted NFT and sends the NFT to the customer.
    * @param The address of the customer.
    * @param The date when the transaction took place
    * @param The price of the transaction.
    * @param Any other information that might be of importance.
    * @return The token id (more used for testing purposes at the moment)
    */
    function createReceiptToken(address _to, uint256 _date, uint256 _price, string memory _others) public onlyAuthorized returns (uint256) {
        uint256 tokenId = safeMint(msg.sender);
        NFTData memory newNFTData = NFTData(_date, _price, _others);
        TokenInformation[tokenId] = newNFTData;
        addressMap[tokenId].push(msg.sender);
        _transfer(msg.sender, _to, tokenId);
        return tokenId;
    }
}
