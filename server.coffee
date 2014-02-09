express = require("express")

app = express()

app.use express.bodyParser()

require("./routes.coffee")(app)

app.listen 8888
