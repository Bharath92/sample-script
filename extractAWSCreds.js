function getValuesFromIntegrationJson(formJSONValues) {
  var result = {};
  formJSONValues.forEach(
    function (jsonValue) {
      if(jsonValue.label)
        result[jsonValue.label] = jsonValue.value;
    }
  );

  return result;
}



var jsonValues = getValuesFromIntegrationJson(JSON.parse(process.argv[2]).formJSONValues);
console.log('access_key = "' + jsonValues.aws_access_key_id + '"');
console.log('secret_key = "' + jsonValues.aws_secret_access_key + '"');
