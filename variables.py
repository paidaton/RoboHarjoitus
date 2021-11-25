from RPA.Robocorp.Vault import Vault

secret = Vault().get_secret("secreturl")
salesurl =secret["salesurl"]
