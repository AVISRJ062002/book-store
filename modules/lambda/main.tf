data "archive_file" "package" {
  type        = "zip"
  source_file = var.source_file
  output_path = "${path.module}/${var.function_name}.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Dedicated log group lets us keep retention predictable and avoid default never-expire logs.
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name = var.function_name
  })
}

resource "aws_iam_role" "this" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.tags, {
    Name = "${var.function_name}-role"
  })
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid = "WriteLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.this.arn,
      "${aws_cloudwatch_log_group.this.arn}:*",
      "*",
    ]
  }

  dynamic "statement" {
    for_each = var.attach_to_vpc ? [1] : []

    content {
      sid = "ManageEnis"

      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:AssignPrivateIpAddresses",
        "ec2:UnassignPrivateIpAddresses",
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.secret_arns) > 0 ? [1] : []

    content {
      sid = "ReadSecrets"

      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
      ]

      resources = var.secret_arns
    }
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "${var.function_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.execution.json
}

# Lambda packages a single Python handler file so the sample stays dependency-light and easy to extend.
resource "aws_lambda_function" "this" {
  function_name                  = var.function_name
  description                    = var.description
  role                           = aws_iam_role.this.arn
  handler                        = var.handler
  runtime                        = var.runtime
  architectures                  = var.architectures
  filename                       = data.archive_file.package.output_path
  source_code_hash               = data.archive_file.package.output_base64sha256
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  publish                        = true
  reserved_concurrent_executions = var.reserved_concurrent_executions >= 0 ? var.reserved_concurrent_executions : null

  environment {
    variables = var.environment_variables
  }

  dynamic "vpc_config" {
    for_each = var.attach_to_vpc ? [1] : []

    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  lifecycle {
    precondition {
      condition     = !var.attach_to_vpc || (length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0)
      error_message = "subnet_ids and security_group_ids must be provided when attach_to_vpc is true."
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]

  tags = merge(var.tags, {
    Name = var.function_name
  })
}
