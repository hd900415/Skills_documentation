helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube 

helm repo update

helm search repo sonarqube 
# NAME                    CHART VERSION   APP VERSION     DESCRIPTION                                       
# bitnami/sonarqube       4.1.6           10.3.0          SonarQube(TM) is an open source quality managem...
# sonarqube/sonarqube     10.3.0+2009     10.3.0          SonarQube is a self-managed, automatic code rev...
# sonarqube/sonarqube-dce 10.3.0+2009     10.3.0          SonarQube is a self-managed, automatic code rev...
# sonarqube/sonarqube-lts 2.0.0+463       8.9.10          DEPRECATED SonarQube offers Code Quality and Co...


helm pull bitnami/sonarqube


