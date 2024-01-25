-include .env

deployTokenLending:
	@forge script script/DeployTokenLending.s.sol:DeployTokenLending \
		--account $(ACCOUNT) \
		--password $(PASSWORD) \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--sender $(SENDER) \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--broadcast

deployCollateralLending:
	@forge script script/DeployCollateralLending.s.sol:DeployCollateralLending \
		--account $(ACCOUNT) \
		--password $(PASSWORD) \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--sender $(SENDER) \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--broadcast

deployAdvancedLending:
	@forge script script/DeployAdvancedLending.s.sol:DeployAdvancedLending \
		--account $(ACCOUNT) \
		--password $(PASSWORD) \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--sender $(SENDER) \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--broadcast