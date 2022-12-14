import { Injectable } from '@nestjs/common';
import { readCampaignData } from './utils';

@Injectable()
export class AppService {
  getCampaign(id: string): string {
    throw new Error('Method not implemented.');
  }
  getCampaignList(): any {
    return readCampaignData();
  }
}
