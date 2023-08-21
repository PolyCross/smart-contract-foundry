// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/BridgeSwap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";


contract BridgeSwapTest is Test, IERC1155Receiver {
    event BridgeSwapIn(
        address[] path,
        uint256 amountIn,
        address indexed receiver
    );

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

    function testFail_initialize() public {
        bridgeSwap.Initialize();
    }

    function test_getPoolInfo() public {
        vm.expectRevert();
        bridgeSwap.getPoolInfo(address(tokenA), address(tokenB));

        (ERC20 token0, ERC20 token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        bridgeSwap.initPool(
            address(token0),
            address(token1),
            1e22,
            1e24,
            address(this)
        );

        (
            address token_0,
            address token_1,
            uint256 reserve0,
            uint256 reserve1
        ) = bridgeSwap.getPoolInfo(address(tokenA), address(tokenB));

        assertEq(token_0, address(token0));
        assertEq(token_1, address(token1));
        assertEq(reserve0, 1e22);
        assertEq(reserve1, 1e24);
    }

    function test_initPool() public {
        assertFalse(bridgeSwap.isPoolExists(address(tokenA), address(tokenB)));
        assertEq(bridgeSwap.poolTotalAmount(), 0);

        vm.expectRevert();
        bridgeSwap.initPool(
            address(tokenA),
            address(tokenA),
            1e22,
            1e22,
            address(this)
        );

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

        vm.expectRevert();
        bridgeSwap.initPool(
            address(tokenA),
            address(tokenB),
            1e22,
            1e22,
            address(this)
        );
    }

    function test_addLiquidity() public {
        vm.expectRevert();
        bridgeSwap.addLiquidity(
            address(tokenA),
            address(tokenA),
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

        assertEq(share, 1e22);
    }

    function test_swapIn() public {
        bridgeSwap.addLiquidity(
            address(tokenA),
            address(tokenB),
            1e24,
            1e24,
            address(this)
        );

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        vm.expectEmit();
        emit BridgeSwapIn(path, 1e21, address(this));

        bridgeSwap.swapIn(1e21, 0, path);

        vm.expectRevert();
        bridgeSwap.swapIn(1e21, 1e24, path);
    }

    function test_swapOut() public {
        bridgeSwap.addLiquidity(
            address(tokenA),
            address(tokenB),
            1e24,
            1e24,
            address(this)
        );

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256 balanceOfTokenB_BeforeSwap = tokenB.balanceOf(address(this));

        uint256 amountOut = bridgeSwap.calculateAmountOut(1e21, path);

        bridgeSwap.swapOut(1e21, path, address(this));

        uint256 balanceOfTokenB_AfterSwap = tokenB.balanceOf(address(this));

        assertEq(
            balanceOfTokenB_AfterSwap,
            balanceOfTokenB_BeforeSwap + amountOut
        );
    }

    // TODO
    function test_removeLiquidity() public {
        uint256 shares = bridgeSwap.addLiquidity(address(tokenA), address(tokenB), 1e24, 1e24, address(this));
        
        bridgeSwap.removeLiquidity(address(tokenA), address(tokenB), shares, address(this));

        assertEq(tokenA.balanceOf(address(this)), 1e26);
        assertEq(tokenB.balanceOf(address(this)), 1e26);

        (address token0, address token1, uint256 reserve0, uint256 reserve1) = bridgeSwap.getPoolInfo(address(tokenA), address(tokenB));
        assertEq(reserve0, 0);
        assertEq(reserve1, 0);
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
