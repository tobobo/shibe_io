express = require("express")

app = express()

require("./routes.coffee")(app)

app.listen 8888
