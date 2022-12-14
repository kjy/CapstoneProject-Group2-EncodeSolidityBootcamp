import { Component } from '@angular/core';

@Component({
  selector: 'app-campaigns',
  templateUrl: './campaigns.component.html',
  styleUrls: ['./campaigns.component.css']
})
export class CampaignsComponent {
  campaignList = [
    {
      'name': 'Name 1',
      'description': 'Description 1',
      'goal': 200,
      'raised': 101
    },
    {
      'name': 'Name 2',
      'description': 'Description 2',
      'goal': 20,
      'raised': 1
    },
    {
      'name': 'Name 3',
      'description': 'Description 3',
      'goal': 2000,
      'raised': 51
    },
  ]

  getRandomColor() {
    let letters1 = 'FFFFFFFFFFFF';
    let letters2 = 'FFFF'
    let color = '#';
    for (var i = 0; i < 6; i++) {
      if (i % 2 == 1) {
        color += letters1[Math.floor(Math.random() * 12)];
      }
      else {
        color += letters2[Math.floor(Math.random() * 4)];
      }
    }
    return color;
  }
}
