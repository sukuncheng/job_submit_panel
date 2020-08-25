%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Change of Basis (Matthias Rabatel Post-doc 2016-2017)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Changing coordinate from base B1 to base B2;
% P1 matrix n x 2 coordinates in B1
% P2 matrix n x 2 coordinates in B2
% 
% B1 = [O;e1;e2] | B2 = [O';e1';e2']; O', e1' and e2' in B1
% e1' = a*e1 + b*e2 | e2' = c*e1 + d*e2
%
% P transition matrix from B2 to B1:
%                 e1'    e2'
%  P =    		  a      c     e1
%                 b      d     e2
%
% ex: 	e1' in B1
%		(a, 		
%		b)	= P	(1,
%				0)
%				e1' in B2
%
% e1 = P^-1 e'1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P2 = base_chg(P1,B1,B2)

	% Translation O'O:
	n = size(P1,1);
	vec = B1(1,:)-B2(1,:);
	vec = repmat(vec',1,n);

	% construction of P^-1:
	a = B2(2,1); b = B2(2,2); c = B2(3,1); d = B2(3,2);
	assert(a*d-b*c~=0,'B2 is not a basis, vector null or non linearly independent')
	inv_P = 1/(a*d-b*c)*[d -c;-b a];

	% Transition B1 to B2
    P2 = inv_P*(P1'+vec);
    P2 = P2';
end