from hacksport.problem import Compiled
import string

class Problem(Compiled):
    program_name='vuln'
    compiler_sources = ["vuln.c"]

    def generate_flag(self, random):
        lettersAndDigits = string.ascii_letters + string.digits
        flag = ''.join(random.choice(lettersAndDigits) for i in range(24))
        return "hthshacks{" + flag + "}"
