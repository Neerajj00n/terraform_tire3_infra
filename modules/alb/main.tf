resource "aws_lb" "ecs_alb" {
 name               = "${var.project_name}-ecs-alb"
 internal           = false
 load_balancer_type = "application"
 security_groups    = [var.alb_security_group_id]
 subnets            = var.public_subnets
 
 tags = {
   name = "ecs-alb"
 }
}


resource "aws_lb" "ecs_internal_alb" {
 name               = "${var.project_name}-internal-ecs-alb"
 internal           = true
 load_balancer_type = "application"
 security_groups    = [var.alb_security_group_id]
 subnets            = var.private_subnets

 tags = {
   name = "ecs-alb"
 }
}

     #>>>>> Targate group
resource "aws_lb_target_group" "crm-ecs-tg" {
 name        = "crm-ecs-TGroup"
 port        = 8000
 protocol    = "HTTP"
 target_type = "ip"
 vpc_id      = var.vpc_id

 health_check {
   path = "/health"
 }
}

resource "aws_lb_target_group" "crm-internal-ecs-tg" {
 name        = "crm-ecs-internal-TGroup"
 port        = 8000
 protocol    = "HTTP"
 target_type = "ip"
 vpc_id      = var.vpc_id

 health_check {
   path = "/health"
 }
}
resource "aws_lb_target_group" "crm-payin-tg" {
 name        = "crm-payin-TGroup"
 port        = 8000
 protocol    = "HTTP"
 target_type = "ip"
 vpc_id      = var.vpc_id

 health_check {
   path = "/health"
 }
}

resource "aws_lb_target_group" "crm-payin-internal-tg" {
 name        = "crm-payin-internal-TGroup"
 port        = 8000
 protocol    = "HTTP"
 target_type = "ip"
 vpc_id      = var.vpc_id

 health_check {
   path = "/health"
 }
}

     #>>> listner

resource "aws_lb_listener" "ecs_alb_listener" {
 load_balancer_arn = aws_lb.ecs_alb.arn
 port              = 80
 protocol          = "HTTP"

 default_action {
   type = "forward"
   target_group_arn = aws_lb_target_group.crm-ecs-tg.arn
 }
}

resource "aws_lb_listener" "ecs_internal_alb_listener" {
 load_balancer_arn = aws_lb.ecs_internal_alb.arn
 port              = 80
 protocol          = "HTTP"

 default_action {
   type = "forward"
   target_group_arn = aws_lb_target_group.crm-internal-ecs-tg.arn
 }
}

resource "aws_lb_listener" "payin_ecs_alb_listener" {
 load_balancer_arn = aws_lb.ecs_alb.arn
 port              = 443
 protocol          = "HTTPS"
 ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
 certificate_arn   = var.alb_cert # Replace with your certificate ARN


 default_action {
   type = "forward"
   target_group_arn = aws_lb_target_group.crm-payin-tg.arn
 }
}

resource "aws_lb_listener" "payin_ecs_internal_alb_listener" {
 load_balancer_arn = aws_lb.ecs_internal_alb.arn
 port              = 443
 protocol          = "HTTPS"
 ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
 certificate_arn   = var.alb_cert # Replace with your certificate ARN


 default_action {
   type = "forward"
   target_group_arn = aws_lb_target_group.crm-payin-internal-tg.arn
 }
}

####################>>>>>Auto Scaling Group<<<<<<<<##############
#######################################################
#load_balancer rules

resource "aws_lb_listener_rule" "ElasticLoadBalancingV2ListenerRule2" {
    priority = "250"
    listener_arn = aws_lb_listener.payin_ecs_internal_alb_listener.arn
    condition {
        path_pattern {
            values = [
                "/api/v1/payin",
                "/api/v1/payin/",
                "/api/v1/payin/*"
            ]
        }
       
    }
    condition {
       host_header {
            values = [
                "api.${var.domain}"
            ]
        }

    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.crm-payin-internal-tg.arn
    }
    tags = {Environment = "prod",
            name= "rule"}
}

resource "aws_lb_listener_rule" "ElasticLoadBalancingV2ListenerRule1" {
    priority = "350"
    listener_arn = aws_lb_listener.payin_ecs_internal_alb_listener.arn
    condition {
       host_header {
            values = [
                "api.${var.domain}"
            ]
        }

    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.crm-internal-ecs-tg.arn
    }
    tags = {Environment = "prod",
            name= "rule"}
}


resource "aws_lb_listener_rule" "ElasticLoadBalancingV2ListenerRule3" {
    priority = "300"
    listener_arn = aws_lb_listener.payin_ecs_alb_listener.arn
    condition {
        host_header {
            values = [
                "api.${var.domain}"
            ]
        }
    }
    condition {
        path_pattern {
            values = [
                "/api/v1/payin",
                "/api/v1/payin/",
                "/api/v1/payin/*"
            ]
        }
       
    }
    
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.crm-payin-tg.arn

    }
    tags = {
      Environment = "prod",
      name= "rule"
      }
    
}

resource "aws_lb_listener_rule" "ElasticLoadBalancingV2ListenerRule4" {
    priority = "400"
    listener_arn = aws_lb_listener.payin_ecs_alb_listener.arn
    condition {
        host_header {
            values = [
                "api.${var.domain}"
            ]
        }
    }

    
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.crm-ecs-tg.arn

    }
    tags = {
      Environment = "prod",
      name= "rule"
      }
    
}