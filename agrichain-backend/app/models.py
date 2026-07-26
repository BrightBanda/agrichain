"""Imports every ORM model so the SQLAlchemy mapper registry is complete.

Relationships are declared by class *name* (`relationship("SupplierProfile")`),
which SQLAlchemy resolves lazily at mapper-configuration time. If only some
model modules have been imported, that lookup fails with:

    InvalidRequestError: expression 'SupplierProfile' failed to locate a name

Anything that touches the ORM outside the FastAPI app — maintenance scripts,
one-off queries, tests — should import this module rather than reaching for
individual model modules and hoping the set is complete.

    from app import models  # noqa: F401  (registers every mapper)
"""

from app.modules.activities import models as activities_models  # noqa: F401
from app.modules.blockchain import models as blockchain_models  # noqa: F401
from app.modules.credit_engine import models as credit_models  # noqa: F401
from app.modules.farmers import models as farmers_models  # noqa: F401
from app.modules.loans import models as loans_models  # noqa: F401
from app.modules.products import models as products_models  # noqa: F401
from app.modules.suppliers import models as suppliers_models  # noqa: F401
