import { Injectable } from '@nestjs/common';
import { readCampaignData, readCampaignListData } from './utils';

@Injectable()
export class AppService {
  getCampaign(id: string): string {
    return readCampaignData(id);
  }
  getCampaignList(): any {
    return readCampaignListData();
  }
}
