// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.30;

// ███████╗ ██████╗██╗  ██╗ ██████╗   ███╗   ███╗ █████╗ ██████╗ ██╗  ██╗███████╗████████╗
// ██╔════╝██╔════╝██║  ██║██╔═══██╗  ████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝██╔════╝╚══██╔══╝
// █████╗  ██║     ███████║██║   ██║  ██╔████╔██║███████║██████╔╝█████╔╝ █████╗     ██║
// ██╔══╝  ██║     ██╔══██║██║   ██║  ██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ ██╔══╝     ██║
// ███████╗╚██████╗██║  ██║╚██████╔╝  ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗███████╗   ██║
// ╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝
// =================================== EchoPoints ====================================
// =================================== Summer 2025 ===================================

import {Ownable2Step, Ownable} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

/**
 * @title Echo Points Contract
 * @author Dynabits.org
 * @notice A simple Echo point tracking smart contract.
 */
contract EchoPoints is Ownable2Step, ERC20 {
    /********************************\
    |-*-*-*-*-*   STATES   *-*-*-*-*-|
    \********************************/
    uint256 private _totalPointSupply;
    mapping(address => bool) public isEPcontributor;
    mapping(address => uint256) private echoPointsBalances;

    /********************************\
    |-*-*-*-*-*   EVENTS   *-*-*-*-*-|
    \********************************/
    /**
     * @notice Emitted when a new address is added as a Echo Contributor.
     * @param contributor The address added as the contributor.
     */
    event EchoContributorAdded(address indexed contributor);
    /**
     * @notice Emitted when an address is removed as a Echo Contributor.
     * @param contributor The address removed as the contributor.
     */
    event EchoContributorRemoved(address indexed contributor);

    /********************************\
    |-*-*-*-*-*   ERRORS   *-*-*-*-*-|
    \********************************/
    /// @notice The address is already a Echo contributor
    error AlreadyEchoContributor();
    /// @notice The array lengths are mismatched
    error ArrayLengthMismatch();
    /**
     * @notice The amount of Echo points is insufficient.
     * @param available The amount of Echo points available.
     * @param attempted The amount of Echo points attempted to be removed.
     */
    error InsufficientEchoPoints(uint256 available, uint256 attempted);
    /// @notice Only Echo contributor is allowed to perform this call
    error NotEchoContributor();
    /// @notice The EP token is not allowed to be transferred
    error TransferNotAllowed();

    /*******************************\
    |-*-*-*-*   MODIFIERS   *-*-*-*-|
    \*******************************/
    /**
     * @notice Checks if an address is a Echo contributor.
     * @dev The operation will be reverted if the caller is not a Echo contributor.
     */
    modifier onlyEchoContributor() {
        if (!isEPcontributor[msg.sender]) revert NotEchoContributor();
        _;
    }

    /******************************\
    |-*-*-*-*   BUILT-IN   *-*-*-*-|
    \******************************/
    /**
     * @notice Used to initialize the smart contract.
     */
    constructor(address owner) Ownable(owner) ERC20("Echo Points", "EP") {}

    /*******************************\
    |*-*-*-*   EXTERNALS   *-*-*-*-*|
    \*******************************/
    /**
     * @notice Adds a Echo contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Echo contributor to add.
     */
    function addEchoContributor(address _contributor) external onlyOwner {
        if (isEPcontributor[_contributor]) revert AlreadyEchoContributor();
        isEPcontributor[_contributor] = true;
        emit EchoContributorAdded(_contributor);
    }

    /**
     * @notice Removes a Echo contributor.
     * @dev Can only be called by the owner.
     * @param _contributor The address of the Echo contributor to remove.
     */
    function removeEchoContributor(address _contributor) external onlyOwner {
        if (!isEPcontributor[_contributor]) revert NotEchoContributor();
        isEPcontributor[_contributor] = false;
        emit EchoContributorRemoved(_contributor);
    }

    /**
     * @notice Adds Echo points to a recipient.
     * @dev Can only be called by a Echo contributor.
     * @param _recipient Recipient of the Echo points.
     * @param _amount Amount of Echo points to add to the recipient.
     */
    function addEchoPoints(
        address _recipient,
        uint256 _amount
    ) external onlyEchoContributor {
        echoPointsBalances[_recipient] += _amount;
        _totalPointSupply += _amount;
        emit Transfer(address(0), _recipient, _amount);
    }

    /**
     * @notice Removes Echo points from a point owner.
     * @dev Can only be called by a Echo contributor.
     * @dev Can only remove the amount of Echo points that the point owner has.
     * @param _pointOwner Owner of the Echo points being removed.
     * @param _amount Amount of Echo points to remove from the point owner.
     */
    function removeEchoPoints(
        address _pointOwner,
        uint256 _amount
    ) external onlyEchoContributor {
        if (echoPointsBalances[_pointOwner] < _amount) {
            revert InsufficientEchoPoints(
                echoPointsBalances[_pointOwner],
                _amount
            );
        }
        echoPointsBalances[_pointOwner] -= _amount;
        _totalPointSupply -= _amount;
        emit Transfer(_pointOwner, address(0), _amount);
    }

    /**
     * @notice Adds Echo points to multiple recipients.
     * @dev Can only be called by a Echo contributor.
     * @dev If the arrays are different lengths, the operation will be reverted.
     * @param _recipients An array of recipients of the Echo points.
     * @param _amounts An array of amounts of Echo points to add to the recipients.
     */
    function bulkAddEchoPoints(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external onlyEchoContributor {
        if (_recipients.length != _amounts.length) revert ArrayLengthMismatch();
        for (uint256 i; i < _recipients.length; ) {
            echoPointsBalances[_recipients[i]] += _amounts[i];
            _totalPointSupply += _amounts[i];
            emit Transfer(address(0), _recipients[i], _amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Removes Echo points from multiple point owners.
     * @dev Can only be called by a Echo contributor.
     * @dev If the arrays are different lengths, the operation will be reverted.
     * @dev Can only remove the amount of Echo points that the point owner has.
     * @param _pointOwners An array of owners of the Echo points being removed.
     * @param _amounts An array of amounts of Echo points to remove from the point owners.
     */
    function bulkRemoveEchoPoints(
        address[] calldata _pointOwners,
        uint256[] calldata _amounts
    ) external onlyEchoContributor {
        if (_pointOwners.length != _amounts.length)
            revert ArrayLengthMismatch();
        for (uint256 i; i < _pointOwners.length; ) {
            if (echoPointsBalances[_pointOwners[i]] < _amounts[i]) {
                revert InsufficientEchoPoints(
                    echoPointsBalances[_pointOwners[i]],
                    _amounts[i]
                );
            }
            echoPointsBalances[_pointOwners[i]] -= _amounts[i];
            _totalPointSupply -= _amounts[i];
            emit Transfer(_pointOwners[i], address(0), _amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /*****************************\
    |-*-*-*-*   GETTERS   *-*-*-*-|
    \*****************************/
    /**
     * @notice Retrieves the Echo points balances of multiple point owners at the same time.
     * @param _pointOwners An array of point owners.
     * @return An array of Echo points balances.
     */
    function bulkEchoPointsBalances(
        address[] calldata _pointOwners
    ) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_pointOwners.length);

        for (uint256 i; i < _pointOwners.length; ) {
            balances[i] = echoPointsBalances[_pointOwners[i]];

            unchecked {
                ++i;
            }
        }

        return balances;
    }

    /**
     * @notice Retrieves the Echo points balance of an account.
     * @dev This overrides the ERC20 function because we don't have access to `_totalSupply` and we aren't using the
     *  internal transfer method.
     * @param account The account to retrieve the Echo points balance of.
     * @return The Echo points balance of the account.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return echoPointsBalances[account];
    }

    /**
     * @notice Retrieves the total supply of Echo points.
     * @dev This overrides the ERC20 function because we don't have access to `_totalSupply` and we aren't using the
     *  internal transfer method.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalPointSupply;
    }

    /**
     * @notice Retrieves the number of decimals for the Echo points.
     * @dev This function is an override of the ERC20 function, so that we can pass the 0 value.
     */
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    /**
     * @notice The override of the transfer method to prevent the Echo token from being transferred.
     * @dev This function will always revert as we don't allow Echo transfers.
     * @param recipient The recipient of the Echo points.
     * @param amount The amount of Echo points to transfer.
     * @return A boolean indicating if the transfer was successful.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public pure override returns (bool) {
        (recipient, amount) = (address(0), 0);
        revert TransferNotAllowed();
    }

    /**
     * @notice The override of the transferFrom method to prevent the Echo token from being transferred.
     * @dev This function will always revert as we don't allow Echo transfers.
     * @param sender The sender of the Echo points.
     * @param recipient The recipient of the Echo points.
     * @param amount The amount of Echo points to transfer.
     * @return A boolean indicating if the transfer was successful.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public pure override returns (bool) {
        (sender, recipient, amount) = (address(0), address(0), 0);
        revert TransferNotAllowed();
    }
}
