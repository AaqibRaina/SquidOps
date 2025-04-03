# Subsquid Infrastructure Cost Analysis (2025-04-03)

This report provides a detailed cost breakdown for the Subsquid infrastructure module with different configurations and traffic levels.

## Cost Summary

| Configuration | Traffic Level | Monthly Cost |
|---------------|--------------|--------------|
| Basic | 500K-1M requests/month | $146.8652 |
| Balanced | 500K-1M requests/month | $138.8252 |
| Aggressive | 500K-1M requests/month | $79.4251 |
| Basic | 5M-10M requests/month | $370.0854 |
| Balanced | 5M-10M requests/month | $271.3854 |
| Aggressive | 5M-10M requests/month | $187.1653 |

## Detailed Cost Breakdown

### Basic Configuration (500K-1M requests/month)

```
Project: main

 Name                                                          Monthly Qty  Unit              Monthly Cost    
                                                                                                              
 aws_ecs_service.subsquid                                                                                     
 ├─ Per GB per hour                                                      4  GB                      $12.98    
 └─ Per vCPU per hour                                                    2  CPU                     $59.10    
                                                                                                              
 aws_db_instance.subsquid[0]                                                                                  
 ├─ Database instance (on-demand, Single-AZ, db.t3.medium)             730  hours                   $52.56    
 ├─ Storage (general purpose SSD, gp3)                                  20  GB                       $2.30    
 └─ Additional backup storage                               Monthly cost depends on usage: $0.095 per GB      
                                                                                                              
 aws_lb.subsquid[0]                                                                                           
 ├─ Application load balancer                                          730  hours                   $16.43    
 └─ Load balancer capacity units                            Monthly cost depends on usage: $5.84 per LCU      
                                                                                                              
 aws_efs_file_system.subsquid                                                                                 
 └─ Storage (standard)                                                  10  GB                       $3.00  * 
                                                                                                              
 aws_route53_zone.private                                                                                     
 └─ Hosted zone                                                          1  months                   $0.50    
                                                                                                              
 aws_cloudwatch_log_group.subsquid                                                                            
 ├─ Data ingested                                           Monthly cost depends on usage: $0.50 per GB       
 ├─ Archival Storage                                        Monthly cost depends on usage: $0.03 per GB       
 └─ Insights queries data scanned                           Monthly cost depends on usage: $0.005 per GB      
                                                                                                              
 OVERALL TOTAL                                                                                     $146.87 

*Usage costs were estimated using infracost-usage.yml, see docs for other options.

──────────────────────────────────
46 cloud resources were detected:
∙ 7 were estimated
∙ 38 were free
∙ 1 is not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━━━━┓
┃ Project                                            ┃ Baseline cost ┃ Usage cost* ┃ Total cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━╋━━━━━━━━━━━━┫
┃ main                                               ┃          $144 ┃          $3 ┃       $147 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━┻━━━━━━━━━━━━┛
```

### Balanced Configuration (500K-1M requests/month)

```
Project: main

 Name                                                Monthly Qty  Unit                  Monthly Cost    
                                                                                                        
 aws_ecs_service.subsquid                                                                               
 ├─ Per GB per hour                                            4  GB                          $12.98    
 └─ Per vCPU per hour                                          2  CPU                         $59.10    
                                                                                                        
 aws_elasticache_replication_group.subsquid[0]                                                          
 └─ ElastiCache (on-demand, cache.t4g.small)               1,460  hours                       $46.72    
                                                                                                        
 aws_lb.subsquid[0]                                                                                     
 ├─ Application load balancer                                730  hours                       $16.43    
 └─ Load balancer capacity units                Monthly cost depends on usage: $5.84 per LCU            
                                                                                                        
 aws_efs_file_system.subsquid                                                                           
 ├─ Storage (standard)                                        10  GB                           $3.00  * 
 ├─ Storage (standard, infrequent access)       Monthly cost depends on usage: $0.025 per GB            
 ├─ Read requests (infrequent access)                          5  GB                           $0.05  * 
 └─ Write requests (infrequent access)                         5  GB                           $0.05  * 
                                                                                                        
 aws_route53_zone.private                                                                               
 └─ Hosted zone                                                1  months                       $0.50    
                                                                                                        
 aws_cloudwatch_log_group.subsquid                                                                      
 ├─ Data ingested                               Monthly cost depends on usage: $0.50 per GB             
 ├─ Archival Storage                            Monthly cost depends on usage: $0.03 per GB             
 └─ Insights queries data scanned               Monthly cost depends on usage: $0.005 per GB            
                                                                                                        
 aws_rds_cluster.subsquid[0]                                                                            
 ├─ Storage                                     Monthly cost depends on usage: $0.10 per GB             
 ├─ I/O requests                                Monthly cost depends on usage: $0.20 per 1M requests    
 └─ Snapshot export                             Monthly cost depends on usage: $0.01 per GB             
                                                                                                        
 aws_rds_cluster_instance.subsquid[0]                                                                   
 └─ Aurora serverless v2                        Monthly cost depends on usage: $0.12 per ACU-hours      
                                                                                                        
 OVERALL TOTAL                                                                               $138.83 

*Usage costs were estimated using infracost-usage.yml, see docs for other options.

──────────────────────────────────
52 cloud resources were detected:
∙ 9 were estimated
∙ 42 were free
∙ 1 is not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━━━━┓
┃ Project                                            ┃ Baseline cost ┃ Usage cost* ┃ Total cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━╋━━━━━━━━━━━━┫
┃ main                                               ┃          $136 ┃          $3 ┃       $139 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━┻━━━━━━━━━━━━┛
```

### Aggressive Configuration (500K-1M requests/month)

```
Project: main

 Name                                                Monthly Qty  Unit                  Monthly Cost    
                                                                                                        
 aws_ecs_service.subsquid                                                                               
 ├─ Per GB per hour                                            2  GB                           $6.49    
 └─ Per vCPU per hour                                          1  CPU                         $29.55    
                                                                                                        
 aws_elasticache_replication_group.subsquid[0]                                                          
 └─ ElastiCache (on-demand, cache.t4g.micro)               1,460  hours                       $23.36    
                                                                                                        
 aws_lb.subsquid[0]                                                                                     
 ├─ Application load balancer                                730  hours                       $16.43    
 └─ Load balancer capacity units                Monthly cost depends on usage: $5.84 per LCU            
                                                                                                        
 aws_efs_file_system.subsquid                                                                           
 ├─ Storage (standard)                                        10  GB                           $3.00  * 
 ├─ Storage (standard, infrequent access)       Monthly cost depends on usage: $0.025 per GB            
 ├─ Read requests (infrequent access)                          5  GB                           $0.05  * 
 └─ Write requests (infrequent access)                         5  GB                           $0.05  * 
                                                                                                        
 aws_route53_zone.private                                                                               
 └─ Hosted zone                                                1  months                       $0.50    
                                                                                                        
 aws_cloudwatch_log_group.subsquid                                                                      
 ├─ Data ingested                               Monthly cost depends on usage: $0.50 per GB             
 ├─ Archival Storage                            Monthly cost depends on usage: $0.03 per GB             
 └─ Insights queries data scanned               Monthly cost depends on usage: $0.005 per GB            
                                                                                                        
 aws_rds_cluster.subsquid[0]                                                                            
 ├─ Storage                                     Monthly cost depends on usage: $0.10 per GB             
 ├─ I/O requests                                Monthly cost depends on usage: $0.20 per 1M requests    
 └─ Snapshot export                             Monthly cost depends on usage: $0.01 per GB             
                                                                                                        
 aws_rds_cluster_instance.subsquid[0]                                                                   
 └─ Aurora serverless v2                        Monthly cost depends on usage: $0.12 per ACU-hours      
                                                                                                        
 OVERALL TOTAL                                                                                $79.43 

*Usage costs were estimated using infracost-usage.yml, see docs for other options.

──────────────────────────────────
52 cloud resources were detected:
∙ 9 were estimated
∙ 42 were free
∙ 1 is not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━━━━┓
┃ Project                                            ┃ Baseline cost ┃ Usage cost* ┃ Total cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━╋━━━━━━━━━━━━┫
┃ main                                               ┃           $76 ┃          $3 ┃        $79 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━┻━━━━━━━━━━━━┛
```

### Basic Configuration (5M-10M requests/month)

```
Project: main

 Name                                                         Monthly Qty  Unit              Monthly Cost    
                                                                                                             
 aws_db_instance.subsquid[0]                                                                                 
 ├─ Database instance (on-demand, Single-AZ, db.r5.large)             730  hours                  $182.50    
 ├─ Storage (general purpose SSD, gp3)                                100  GB                      $11.50    
 └─ Additional backup storage                              Monthly cost depends on usage: $0.095 per GB      
                                                                                                             
 aws_ecs_service.subsquid                                                                                    
 ├─ Per GB per hour                                                     8  GB                      $25.96    
 └─ Per vCPU per hour                                                   4  CPU                    $118.20    
                                                                                                             
 aws_lb.subsquid[0]                                                                                          
 ├─ Application load balancer                                         730  hours                   $16.43    
 └─ Load balancer capacity units                           Monthly cost depends on usage: $5.84 per LCU      
                                                                                                             
 aws_efs_file_system.subsquid                                                                                
 └─ Storage (standard)                                                 50  GB                      $15.00  * 
                                                                                                             
 aws_route53_zone.private                                                                                    
 └─ Hosted zone                                                         1  months                   $0.50    
                                                                                                             
 aws_cloudwatch_log_group.subsquid                                                                           
 ├─ Data ingested                                          Monthly cost depends on usage: $0.50 per GB       
 ├─ Archival Storage                                       Monthly cost depends on usage: $0.03 per GB       
 └─ Insights queries data scanned                          Monthly cost depends on usage: $0.005 per GB      
                                                                                                             
 OVERALL TOTAL                                                                                    $370.09 

*Usage costs were estimated using infracost-usage.yml, see docs for other options.

──────────────────────────────────
46 cloud resources were detected:
∙ 7 were estimated
∙ 38 were free
∙ 1 is not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━━━━┓
┃ Project                                            ┃ Baseline cost ┃ Usage cost* ┃ Total cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━╋━━━━━━━━━━━━┫
┃ main                                               ┃          $355 ┃         $15 ┃       $370 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━┻━━━━━━━━━━━━┛
```

### Balanced Configuration (5M-10M requests/month)

```
Project: main

 Name                                                Monthly Qty  Unit                  Monthly Cost    
                                                                                                        
 aws_ecs_service.subsquid                                                                               
 ├─ Per GB per hour                                            8  GB                          $25.96    
 └─ Per vCPU per hour                                          4  CPU                        $118.20    
                                                                                                        
 aws_elasticache_replication_group.subsquid[0]                                                          
 └─ ElastiCache (on-demand, cache.t4g.medium)              1,460  hours                       $94.90    
                                                                                                        
 aws_lb.subsquid[0]                                                                                     
 ├─ Application load balancer                                730  hours                       $16.43    
 └─ Load balancer capacity units                Monthly cost depends on usage: $5.84 per LCU            
                                                                                                        
 aws_efs_file_system.subsquid                                                                           
 ├─ Storage (standard)                                        50  GB                          $15.00  * 
 ├─ Storage (standard, infrequent access)       Monthly cost depends on usage: $0.025 per GB            
 ├─ Read requests (infrequent access)                         20  GB                           $0.20  * 
 └─ Write requests (infrequent access)                        20  GB                           $0.20  * 
                                                                                                        
 aws_route53_zone.private                                                                               
 └─ Hosted zone                                                1  months                       $0.50    
                                                                                                        
 aws_cloudwatch_log_group.subsquid                                                                      
 ├─ Data ingested                               Monthly cost depends on usage: $0.50 per GB             
 ├─ Archival Storage                            Monthly cost depends on usage: $0.03 per GB             
 └─ Insights queries data scanned               Monthly cost depends on usage: $0.005 per GB            
                                                                                                        
 aws_rds_cluster.subsquid[0]                                                                            
 ├─ Storage                                     Monthly cost depends on usage: $0.10 per GB             
 ├─ I/O requests                                Monthly cost depends on usage: $0.20 per 1M requests    
 └─ Snapshot export                             Monthly cost depends on usage: $0.01 per GB             
                                                                                                        
 aws_rds_cluster_instance.subsquid[0]                                                                   
 └─ Aurora serverless v2                        Monthly cost depends on usage: $0.12 per ACU-hours      
                                                                                                        
 OVERALL TOTAL                                                                               $271.39 

*Usage costs were estimated using infracost-usage.yml, see docs for other options.

──────────────────────────────────
52 cloud resources were detected:
∙ 9 were estimated
∙ 42 were free
∙ 1 is not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━━━━┓
┃ Project                                            ┃ Baseline cost ┃ Usage cost* ┃ Total cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━╋━━━━━━━━━━━━┫
┃ main                                               ┃          $256 ┃         $15 ┃       $271 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━┻━━━━━━━━━━━━┛
```

### Aggressive Configuration (5M-10M requests/month)

```
Project: main

 Name                                                Monthly Qty  Unit                  Monthly Cost    
                                                                                                        
 aws_ecs_service.subsquid                                                                               
 ├─ Per GB per hour                                            6  GB                          $19.47    
 └─ Per vCPU per hour                                          3  CPU                         $88.65    
                                                                                                        
 aws_elasticache_replication_group.subsquid[0]                                                          
 └─ ElastiCache (on-demand, cache.t4g.small)               1,460  hours                       $46.72    
                                                                                                        
 aws_lb.subsquid[0]                                                                                     
 ├─ Application load balancer                                730  hours                       $16.43    
 └─ Load balancer capacity units                Monthly cost depends on usage: $5.84 per LCU            
                                                                                                        
 aws_efs_file_system.subsquid                                                                           
 ├─ Storage (standard)                                        50  GB                          $15.00  * 
 ├─ Storage (standard, infrequent access)       Monthly cost depends on usage: $0.025 per GB            
 ├─ Read requests (infrequent access)                         20  GB                           $0.20  * 
 └─ Write requests (infrequent access)                        20  GB                           $0.20  * 
                                                                                                        
 aws_route53_zone.private                                                                               
 └─ Hosted zone                                                1  months                       $0.50    
                                                                                                        
 aws_cloudwatch_log_group.subsquid                                                                      
 ├─ Data ingested                               Monthly cost depends on usage: $0.50 per GB             
 ├─ Archival Storage                            Monthly cost depends on usage: $0.03 per GB             
 └─ Insights queries data scanned               Monthly cost depends on usage: $0.005 per GB            
                                                                                                        
 aws_rds_cluster.subsquid[0]                                                                            
 ├─ Storage                                     Monthly cost depends on usage: $0.10 per GB             
 ├─ I/O requests                                Monthly cost depends on usage: $0.20 per 1M requests    
 └─ Snapshot export                             Monthly cost depends on usage: $0.01 per GB             
                                                                                                        
 aws_rds_cluster_instance.subsquid[0]                                                                   
 └─ Aurora serverless v2                        Monthly cost depends on usage: $0.12 per ACU-hours      
                                                                                                        
 OVERALL TOTAL                                                                               $187.17 

*Usage costs were estimated using infracost-usage.yml, see docs for other options.

──────────────────────────────────
52 cloud resources were detected:
∙ 9 were estimated
∙ 42 were free
∙ 1 is not supported yet, rerun with --show-skipped to see details

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━━━━┓
┃ Project                                            ┃ Baseline cost ┃ Usage cost* ┃ Total cost ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━╋━━━━━━━━━━━━┫
┃ main                                               ┃          $172 ┃         $15 ┃       $187 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━┻━━━━━━━━━━━━┛
```

## Cost Comparisons

### Basic vs. Balanced (500K-1M requests/month)

Savings: $8.0400 per month (5.00%)

### Balanced vs. Aggressive (500K-1M requests/month)

Savings: $59.4001 per month (42.00%)

### Basic vs. Balanced (5M-10M requests/month)

Savings: $98.7000 per month (26.00%)

### Balanced vs. Aggressive (5M-10M requests/month)

Savings: $84.2201 per month (31.00%)

## Comparison with Subsquid Cloud

| Traffic Level | Our Solution (Aggressive) | Subsquid Cloud | Savings |
|---------------|---------------------------|---------------|---------|
| 500K-1M requests/month | $79.4251 | $600 | $520.5749 (86.00%) |
| 5M-10M requests/month | $187.1653 | $1,750 | $1562.8347 (89.00%) |

## Conclusion

The Subsquid infrastructure module provides significant cost savings compared to Subsquid Cloud, especially with the aggressive optimization configuration. For high-traffic scenarios, the savings are even more substantial.

