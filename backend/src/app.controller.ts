import { Controller, Get, Param } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) { }

  @Get('campaign-list')
  getCampignList(): any {
    var res = this.appService.getCampaignList();
    return res;
  }

  @Get('campaign-list/:id')
  getCampaign(@Param('id') id: string): string {
    return this.appService.getCampaign(id);
  }
}
