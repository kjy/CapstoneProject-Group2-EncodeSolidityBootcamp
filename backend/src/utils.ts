var fs = require("fs");

const CAMPAIGN_LIST_FILE = 'src/data/campaigns/campaign-list.json';


export async function readCampaignData() {
    var data = fs.readFileSync(CAMPAIGN_LIST_FILE);
    data = JSON.parse(data);
    return data;
}

export function getCampaignData() {
    console.log("pulling fresh data")

    // TODO: READ DATA FROM CONTRACT CALLS
    let data: any;

    // PLACEHOLDER - TO BE REMOVED WHEN TODO ABOVE IS IMPLEMENTED
    data = fs.readFileSync('src/data/mock/campaign-list.json');
    data = JSON.parse(data);

    // Write new data to the file
    data = JSON.stringify(data);
    fs.writeFile(CAMPAIGN_LIST_FILE, data, err => {
        // error checking
        if (err) throw err;
        console.log("New data added");
    });

    return
}

