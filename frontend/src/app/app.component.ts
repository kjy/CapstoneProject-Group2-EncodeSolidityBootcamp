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

  constructor() {
    this.shortenWalletAddress = false;
  }

  connectWallet() {
    this.wallet = ethers.Wallet.createRandom();
    console.log(this.wallet.address)
  }

  disconnectWallet() {
    this.wallet = undefined;
  }
}
