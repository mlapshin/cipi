get_travis_build_status = lambda do |repo|
  response = RestClient.get "https://api.travis-ci.org/#{repo}/builds"
  builds = JSON.parse(response.body)
  result = builds[0]["result"]

  if result.nil?
    :error
  elsif result == 0
    :ok
  else
    :fail
  end
end

monitor "formstamp", gpio: 18, interval: 100 do
  get_travis_build_status.("formstamp/formstamp")
end

monitor "fhirbase", gpio: 23, interval: 10 do
  get_travis_build_status.("fhirbase/fhirbase")
end
