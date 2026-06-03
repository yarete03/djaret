resource "aws_resourcegroups_group" "resource_group" {
  name = "${var.project_name}-rg-${terraform.workspace}"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        { Key = "Project", Values = [var.project_name] },
        { Key = "Environment", Values = [terraform.workspace] },
      ]
    })
  }

  tags = var.tags
}

resource "aws_applicationinsights_application" "app_insights" {
  resource_group_name = aws_resourcegroups_group.resource_group.name
  auto_config_enabled = true
  cwe_monitor_enabled = true

  tags = var.tags
}