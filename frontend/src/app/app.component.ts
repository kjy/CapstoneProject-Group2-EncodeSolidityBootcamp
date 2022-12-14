import { Component } from '@angular/core';
import { Wallet } from 'ethers';
import { ethers } from 'ethers';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  wallet: Wallet | undefined;
  shortenWalletAddress: boolean | false;
  showConnectWalletForm: boolean | false;
  walletBalance: number | string | undefined;

  provider: ethers.providers.Provider;

  backendUrl: string | undefined;

  constructor() {
    this.shortenWalletAddress = false;
    this.showConnectWalletForm = false;

    this.provider = ethers.getDefaultProvider("goerli")

    this.backendUrl = "http://localhost:3000"
  }

  connectWallet(secret: string, importMethod: string) {
    if (importMethod == 'mnemonic') {
      this.wallet = ethers.Wallet.fromMnemonic(secret ?? "").connect(this.provider);
    } else {
      this.wallet = new ethers.Wallet(secret ?? "").connect(this.provider);
    }
    if (this.wallet.address.length == 42) {
      this.updateWallet();
    } else {
      const errorMsg = 'Could not import wallet, invalid mnumonic or private key';
      console.log(errorMsg);
      alert(errorMsg);
    }

    this.updateWallet();
    this.showConnectWalletForm = false;
  }

  updateWallet() {
    this.walletBalance = "loading..."

    this.wallet?.getBalance().then((balanceBN) => {
      this.walletBalance = ethers.utils.formatEther(balanceBN);
    })
  }

  refreshWallet() {
    this.updateWallet();
  }

  disconnectWallet() {
    this.wallet = undefined;
  }
}
