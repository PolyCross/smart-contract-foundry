// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/BridgeSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract BridgeSwapTest is Test, IERC1155Receiver {
    ERC20 tokenA;
    ERC20 tokenB;

    BridgeSwap bridgeSwap;

    function setUp() public {
        tokenA = new ERC20("TokenA", "TA");
        tokenB = new ERC20("TokenB", "TB");
        bridgeSwap = new BridgeSwap();
        bridgeSwap.Initialize();

        deal(address(tokenA), address(this), 1e26);
        deal(address(tokenB), address(this), 1e26);

        tokenA.approve(address(bridgeSwap), 1e26);
        tokenB.approve(address(bridgeSwap), 1e26);
    }

    function test_IsPoolExists() public {
        assertFalse(bridgeSwap.isPoolExists(address(tokenA), address(tokenB)));
    }

    function test_PoolTotalAmount() public {
        assertEq(bridgeSwap.poolTotalAmount(), 0);
    }

    function test_InitPool() public {
        uint256 share = bridgeSwap.initPool(
            address(tokenA),
            address(tokenB),
            1e22,
            1e22,
            address(this)
        );
        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenA.balanceOf(address(this));

        assertTrue(bridgeSwap.isPoolExists(address(tokenA), address(tokenB)));
        assertEq(bridgeSwap.poolTotalAmount(), 1);

        assertEq(balanceA, 1e26 - 1e22);
        assertEq(balanceB, 1e26 - 1e22);
        assertEq(share, 1e22);
    }

    function test_AddLiquidity() public {
        uint256 temp = bridgeSwap.initPool(
            address(tokenA),
            address(tokenB),
            1e22,
            1e22,
            address(this)
        );
        uint256 share = bridgeSwap.addLiquidity(
            address(tokenA),
            address(tokenB),
            1e22,
            1e22,
            address(this)
        );
    }

    function test_SwapOut() public {
        uint256 share = bridgeSwap.addLiquidity(
            address(tokenA),
            address(tokenB),
            1e24,
            1e24,
            address(this)
        );

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256 balanceOfToeknB_BeforeSwap = tokenB.balanceOf(address(this));

        uint256 amountOut = bridgeSwap.calculateAmountOut(1e21, path);

        bridgeSwap.swapOut(1e21, path, address(this));

        uint256 balanceOfToeknB_AfterSwap = tokenB.balanceOf(address(this));

        assertEq(balanceOfToeknB_AfterSwap, balanceOfToeknB_BeforeSwap + amountOut);
    }

    // =============================================== ERC1155 Receiver ===============================================

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
