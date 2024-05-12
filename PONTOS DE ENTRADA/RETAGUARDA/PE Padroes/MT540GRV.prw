#include "protheus.ch"

// PE MT540GRV - Ap�s a grava��o das informa��es da tributa��o - SF7
//-- Criado pois, ao alterar a Excessao Fiscal, n�o esta limpando o campo MSEXP pelo padr�o
//-- Fizemos esse PE ate solu��o da matriz (TEMPOR�RIO)
User Function MT540GRV()
Local aSF7 := SF7->( GetArea() )
Local cGrp := SF7->F7_GRTRIB

SF7->( DbSetOrder(1) )
SF7->( DbSeek( xFilial("SF7") + cGrp ) )
while !SF7->( Eof() ) .and. (SF7->F7_FILIAL+SF7->F7_GRTRIB) == (xFilial("SF7") + cGrp)

	RecLock("SF7")
		SF7->F7_MSEXP := ""
	SF7->( MsUnLock() )

	SF7->( DbSkip() )

enddo	

RestArea(aSF7)
Return 	