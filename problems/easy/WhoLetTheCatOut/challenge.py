from hacksport.problem import Remote
import string

class Problem(Remote):
    program_name = "flag.py"

    def generate_flag(self, random):
        lettersAndDigits = string.ascii_letters + string.digits
        flag = ''.join(random.choice(lettersAndDigits) for i in range(24))
        return "hthshacks{" + flag + "}"

