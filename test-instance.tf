# EC2 instance for test
resource "aws_instance" "test_instance" {
    ami           = "ami-0230bd60aa48260c6"
    instance_type = "t2.micro"
    tags = {
    Name = "test_instance"
    }
}