output "launch_templates" {
  value = {
    main = {
      id      = aws_launch_template.main.id
      name    = aws_launch_template.main.name
      version = aws_launch_template.main.latest_version
    }

    task = {
      id      = aws_launch_template.task.id
      name    = aws_launch_template.task.name
      version = aws_launch_template.task.latest_version
    }
  }
}
