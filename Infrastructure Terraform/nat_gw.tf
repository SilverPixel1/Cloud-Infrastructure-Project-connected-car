################### 
# NAT Gateway for private subnets
###################
resource "aws_eip" "connected_car_nat_eip" {
  domain = "vpc"


  tags = {
    Name = "${var.project_name}-nat-eip"
    Project = var.project_name
    Environment = "Development"
  }
} 

resource "aws_nat_gateway" "connected_car_nat_gw" { 
  allocation_id = aws_eip.connected_car_nat_eip.id
  subnet_id = aws_subnet.connected_car_public_subnet[0].id #NAT Gateway muss in einem öffentlichen Subnetz platziert werden

  tags = {
    Name = "${var.project_name}-nat-gw"
    Project = var.project_name
    Environment = "Development"
  }

  depends_on = [ aws_internet_gateway.connected_car_igw] #NAT Gateway benötigt Internet Gateway, um zu funktionieren

}
