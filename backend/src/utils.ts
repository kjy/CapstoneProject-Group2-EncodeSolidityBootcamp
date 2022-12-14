var fs = require("fs");

const CAMPAIGN_LIST_DIR = 'src/data/campaigns/'
const CAMPAIGN_LIST_FILE = CAMPAIGN_LIST_DIR + 'campaign-list.json';



export function readCampaignListData() {
    try {
        var data = fs.readFileSync(CAMPAIGN_LIST_FILE);
        data = JSON.parse(data);
        return data;
    } catch (error) {
        return { "error": error["code"] }
    }
}

export function readCampaignData(id) {
    try {
        var data = fs.readFileSync(CAMPAIGN_LIST_DIR + id + ".json");
        data = JSON.parse(data);
        return data;
    } catch (error) {
        return { "error": error["code"] }
    }
}

export function getCampaignData() {
    console.log("pulling fresh data")

    // TODO: READ DATA FROM CONTRACT CALLS
    let data: any;

    // PLACEHOLDER - TO BE REMOVED WHEN TODO ABOVE IS IMPLEMENTED
    data = fs.readFileSync('src/data/mock/campaign-list.json');
    data = JSON.parse(data);

    // split data for individual campaigns
    data.forEach(item => {
        fs.writeFile(CAMPAIGN_LIST_DIR + item["id"] + ".json", JSON.stringify(item), err => {
            // error checking
            if (err) throw err;
        });
    });

    // Write new data to the file
    data = JSON.stringify(data);
    fs.writeFile(CAMPAIGN_LIST_FILE, data, err => {
        // error checking
        if (err) throw err;
        console.log("New data added");
    });

    return
}

