resource "aws_api_gateway_resource" "resource1" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id 
  path_part   = var.path_part 
}
resource "aws_api_gateway_method" "method2" {
  rest_api_id   = var.rest_api_id2
  resource_id   = aws_api_gateway_resource.resource1.id
  http_method   = var.http_method
  authorization = "NONE" 
}
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = var.rest_api_id3
  resource_id             = aws_api_gateway_resource.resource1.id
  http_method             = aws_api_gateway_method.method2.http_method
  integration_http_method = aws_api_gateway_method.method2.http_method
  type                    = var.type
  uri                     = var.uri     
  depends_on = [aws_api_gateway_method.method2]
  request_templates = {
    "application/json" = <<EOF
{
    "headers": {
        #foreach($param in $input.params().header.keySet())
        "$param": "$util.escapeJavaScript($input.params().header.get($param))"
        #if($foreach.hasNext),#end
        #end
    },
    "body" : $input.json('$')
}
EOF
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = var.rest_api_id4
  resource_id = aws_api_gateway_resource.resource1.id
  http_method = aws_api_gateway_method.method2.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = var.rest_api_id5
  resource_id = aws_api_gateway_resource.resource1.id
  http_method = aws_api_gateway_method.method2.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  
  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
EOF
  }
}