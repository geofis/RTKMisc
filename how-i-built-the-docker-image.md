# How I built the docker image

- I ran this in Ubuntu HOST machine

```{bash}
docker pull oliverstatworx/base-r-tidyverse:latest
docker run -it --rm oliverstatworx/base-r-tidyverse bash #"--rm" ensures the container is removed when I stop it; "--it" stands for "interactive terminal"
```

- Then I ran this in the guest docker machine

```{bash}
apt install software-properties-common
apt update
apt install libcurl4-openssl-dev libssl-dev unixodbc-dev libpq-dev libxml2-dev
apt install libudunits2-dev libgdal-dev libgeos-dev libproj-dev 
R
```

- Within R, I installed the required packages

```{r}
req_pkg <- c("optparse","sf")
install_load_pkg <- function(pkg){
  new_pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new_pkg))
    install.packages(new_pkg, dependencies = TRUE)
  sapply(pkg, function(x) suppressPackageStartupMessages(require(x, character.only = TRUE)))
}
invisible(install_load_pkg(req_pkg))
q()
```

- I STOPPED HERE. I committed the changes to a new repo, by opening a new terminal on the Ubuntu HOST machine before stopping the container

```
docker ps # To get the container ID
docker commit -m "Add dependencies and sf package in R" 61d07b225f54 jmartinez19/base-r-tidyverse-sf

# Actually, I made a mistake so I needed to take additional steps. My commit actually was like this:
# docker commit -m "Add dependencies and sf package in R" 61d07b225f54 base-r-tidyverse-sf
# Since I didn't specified the username of the repo, so I retagged it with:
# docker tag base-r-tidyverse-sf jmartinez19/base-r-tidyverse-sf
# Then, I deleted the other image repo (the one without the username)
```

- Then it was safe to stop the container by issuing an "exit" in the guest docker machine

- Then I logged in docker and finally pushed the image to my dockerhub account:

```
docker login --username USERNAME --password PASS
docker push jmartinez19/base-r-tidyverse-sf:latest
```

- What I did next? See the section Docker of the README file.
