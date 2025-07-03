// Job DSL para crear automáticamente el job de monitoreo
job('villa-alfredo-monitoring-pipeline') {
    description('Pipeline de prueba para generar métricas en Grafana')
    
    scm {
        git {
            remote {
                url('https://github.com/tu-usuario/villa-alfredo.git')
                credentials('github-credentials')
            }
            branch('main')
        }
    }
    
    triggers {
        cron('H/5 * * * *')  // Cada 5 minutos
    }
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/tu-usuario/villa-alfredo.git')
                        credentials('github-credentials')
                    }
                    branch('main')
                }
            }
            scriptPath('ci-cd/Jenkinsfile.monitoring')
        }
    }
    
    properties {
        buildDiscarder {
            strategy {
                logRotator {
                    numToKeepStr('50')
                    daysToKeepStr('30')
                }
            }
        }
    }
}

// Job para el pipeline principal
job('villa-alfredo-main-pipeline') {
    description('Pipeline principal de CI/CD para Villa Alfredo')
    
    scm {
        git {
            remote {
                url('https://github.com/tu-usuario/villa-alfredo.git')
                credentials('github-credentials')
            }
            branch('main')
        }
    }
    
    triggers {
        scm('H/10 * * * *')  // Cada 10 minutos
    }
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/tu-usuario/villa-alfredo.git')
                        credentials('github-credentials')
                    }
                    branch('main')
                }
            }
            scriptPath('ci-cd/Jenkinsfile')
        }
    }
    
    properties {
        buildDiscarder {
            strategy {
                logRotator {
                    numToKeepStr('20')
                    daysToKeepStr('14')
                }
            }
        }
    }
}
