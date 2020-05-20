require 'json'

def register(params)
    @source_field = params["source_field"]
end

# filter runs for every event
# return the list of events to be passed forward
# returning empty list is equivalent to event.cancel
def filter(event)
    # tag if field isn't present
    if event.get(@source_field).nil?
      event.tag("#{@source_field}_not_found")
      return [event]
    end
  
    loadedjson = JSON.parse(event.get(@source_field))
    loadedjson["logMessage"]["app.org"] = loadedjson["logMessage"]["app"]["org"]
    loadedjson["logMessage"]["app.guid"] = loadedjson["logMessage"]["app"]["guid"]
    loadedjson["logMessage"]["app.name"] = loadedjson["logMessage"]["app"]["name"]
    loadedjson["logMessage"]["app.space"] = loadedjson["logMessage"]["app"]["space"]
    loadedjson["logMessage"].delete("app")
    
    event.set("message", loadedjson)
  
    return [event]
  end