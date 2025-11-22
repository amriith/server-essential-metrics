**Scripts to check server performance** 

1. Server memory
2. Server load
3. Server available buffer space and notification to run "Prune"
5. RAM usage and potential improvements
6. Peak load times tracking and chances for improvement
13. Unexpected disk usage spike
4. Server login details and suspected logins and IPs
11. Open port scan and servers listening
12. File integrity, permissions, and ownership monitoring  (Pending)
14. Outdated security packages
15. SSL Certificate expiration  (Pending)
7. Environment variables check
8. Docker container check to find any that have exited and show the last 3 lines of error
9. K8 pod health check  (Pending)
10. Active network connections and port check 
19. I/O bottleneck identification (disk read/write patterns)
20. Network bandwidth utilization tracking
16. Log file rotation and cleanup recommendations
17. Cron job execution status and failures
18. Export reports in multiple formats

iftop -i eth0