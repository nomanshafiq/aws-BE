provider "aws" {
  region = "us-east-1"
}

# -----------------------
# DynamoDB Table for App
# -----------------------
resource "aws_dynamodb_table" "visitor_table" {
  name         = "visitor-counter-12w3-ns2025"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "visitor_id"

  attribute {
    name = "visitor_id"
    type = "S"
  }
}

# -----------------------
# IAM Role for Lambda
# -----------------------
resource "aws_iam_role" "lambda_role" {
  name = "visitor_lambda_role_12w3-ns2025"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda_dynamodb_policy_12w3-ns2025"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.visitor_table.arn
      }
    ]
  })
}

# -----------------------
# Lambda Function
# -----------------------
resource "aws_lambda_function" "visitor_lambda" {
  function_name = "visitor_lambda_12w3-ns2025"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.11"

  filename         = "lambda_function/lambda.zip" # make sure your zip exists
  source_code_hash = filebase64sha256("lambda_function/lambda.zip")
}

# -----------------------
# API Gateway HTTP API
# -----------------------
resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "visitor_api_12w3-ns2025"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.visitor_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_lambda.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# ✅ Added default route (handles root /)
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Existing /visitor route (keep this)
resource "aws_apigatewayv2_route" "visitor_route" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "GET /visitor"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "visitor_stage" {
  api_id      = aws_apigatewayv2_api.visitor_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}

# -----------------------
# Outputs
# -----------------------
output "api_url" {
  value = aws_apigatewayv2_api.visitor_api.api_endpoint
}

output "dynamodb_table" {
  value = aws_dynamodb_table.visitor_table.name
}
