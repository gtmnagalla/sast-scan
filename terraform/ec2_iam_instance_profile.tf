##
#Create one instance profile.
#Create policy attachment that uses AmazonEC2RoleForSSM that allows EC2 to talk to SSM service, and CloudWatchAgentServerPolicy that allows EC2 to talk to CloudWatch service.
#Create policy attachment that uses AmazonSSMManagedInstanceCore allows Systems Manager Session Manager to securely connect to our instances without SSH keys through the AWS console.
#Policy attachment for RDS full access - arn:aws:iam::aws:policy/AmazonRDSDataFullAccess
#Create a custom role policy that will allow EC2 to make API call ssm:GetParameter , the main reason we need to allow this permission again is that we will need CloudWatch agent to load the configuration from SSM service, and the action is using this permission which not include in AmazonEC2RoleForSSM .
#Lastly, the script will create assume role policy for ec2.amazonaws.com .
##

locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
  ]
}

resource "aws_iam_role" "app" {
  name = "EC2-Role"
  path = "/"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Effect" : "Allow"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "app" {
  name   = "EC2-Inline-Policy"
  role   = aws_iam_role.app.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameter"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "app" {
  count      = length(local.role_policy_arns)
  role       = aws_iam_role.app.name
  policy_arn = element(local.role_policy_arns, count.index)
}

resource "aws_iam_instance_profile" "app" {
  name = "EC2-Profile"
  role = aws_iam_role.app.name
}
