# syntax.py : the authoring layer for goal models. Bodies are
# algebra: * is and (shuffled conjunction), + is or (commit to
# one alternative); h <= body records a clause. The algebra is
# sugar only: `<=` compiles bodies to plain tuples
# (('and',..), ('or',..), ('=',x,v), ('link',bag,x), bare Atom)
# and infer.py runs on that data, never on these classes.
of = isinstance

Val = str                       # 't' | 'f'
RULES: "Rules" = {}             # head -> alternative bodies (compiled)

class Term:                     # the __add__/__radd__ trick:
  def __add__(i,o):  return Or(alts(i)+alts(o))   # b+c -> Or
  def __radd__(i,o): return Or(alts(o)+alts(i))
  def __mul__(i,o):  return And(parts(i)+parts(o))# b*c -> And
  def __rmul__(i,o): return And(parts(o)+parts(i))

class Or(Term):
  def __init__(i, xs: list["Body"]): i.xs = xs
class And(Term):
  def __init__(i, xs: list["Body"]): i.xs = xs
class Link(Term):
  def __init__(i, bag: str, x: "Atom"): i.bag, i.x = bag, x
class Atom(Term):               # a value object: two Atoms with
  def __init__(i, name: str): i.name = name      # one name ARE
  def __repr__(i) -> str:     return i.name      # one atom
  def __hash__(i) -> int:     return hash(i.name)
  def __eq__(i,o) -> bool:    return of(o,Atom) and i.name==o.name
  def __le__(i, body: "Body") -> bool:
    RULES.setdefault(i,[]).append(compiled(body)); return True

Body   = Term | tuple | list    # authored | compiled | query
Rules  = dict[Atom, list[Body]]
World  = dict[Atom, Val]        # beliefs in, labels out

def alts(x: Body) -> list[Body]:
  return x.xs if of(x,Or) else [x]
def parts(x: Body) -> list[Body]:
  return x.xs if of(x,And) else [x]
def atoms(names: str) -> list[Atom]:
  return [Atom(n) for n in names.split()]

def makes(x: Atom)    -> Link: return Link('t',  x)
def breaks(x: Atom)   -> Link: return Link('f',  x)
def helps(x: Atom)    -> Link: return Link('ttf',x)
def hurts(x: Atom)    -> Link: return Link('fft',x)

def compiled(g: Body) -> Body:
  "authored term (or legacy (x,v) demand) -> plain data"
  match g:
    case Atom():                    return g
    case Link():                    return ('link', g.bag, g.x)
    case And():                     return ('and', *map(compiled, g.xs))
    case Or():                      return ('or',  *map(compiled, g.xs))
    case (Atom() as x, str() as v): return ('=', x, v)
    case list():                    return [compiled(x) for x in g]
    case tuple():                   return g         # already data
  raise ValueError(g)
