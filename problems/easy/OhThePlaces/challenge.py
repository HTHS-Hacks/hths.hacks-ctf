from hacksport.problem import Challenge, File, Directory
import os
import string

class Problem(Challenge):
    files = []

    def generate_flag(self, random):
        lettersAndDigits = string.ascii_letters + string.digits
        flag = ''.join(random.choice(lettersAndDigits) for i in range(24))
        return "hthshacks{" + flag + "}"


    def setup(self):
        loc = "dirs/{}/{}/{}/flag.txt".format(self.random.randint(1, 9), self.random.randint(1, 9), self.random.randint(1, 9))
        for a in range(1, 10):
            for b in range(1, 10):
                for c in range(1, 10):
                    path = "dirs/{}/{}/{}".format(a, b, c)
                    os.makedirs(path)
                    with open(path+"/no_flag.txt", "w") as f:
                        f.write("")
                    self.files.append(File(path+"/no_flag.txt"))

        with open(loc, "w") as f:
            f.write(self.flag)
        self.files.append(File(loc))
