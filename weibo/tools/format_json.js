fs = require('fs');

let files = process.argv.slice(2);
formatFiles(files);

function formatFiles(files) {
  files.forEach(f => {
    try {
      data = fs.readFileSync(f, 'utf8');
      let json = JSON.parse(data);
      let result = JSON.stringify(json, null, 2);
      fs.writeFileSync(f, result);
      console.log(result);
    } catch (err) {
      console.log("error: ",err);
    }
  })
}
