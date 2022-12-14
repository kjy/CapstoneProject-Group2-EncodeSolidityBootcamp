import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { MaterialModule } from './material/material.module';
import { CampaignsComponent } from './campaigns/campaigns.component';
import { CampaignsModule } from './campaigns/campaigns.module';

@NgModule({
  declarations: [
    AppComponent,
    CampaignsComponent,
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    BrowserAnimationsModule,
    MaterialModule,
    CampaignsModule,
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
