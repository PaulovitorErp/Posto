#INCLUDE "PROTHEUS.CH"
#include "TOTVS.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} TRETE007
Job para leitura de abastecimentos da concentradora.

@author Wellington Gonçalves
@since 19/05/2014
@version 1.0

@param cEmp, characters, grupo de empresa
@param cFil, characters, codigo da filial
@param cDataLimite, characters, data limite
@param cHoraLimite, characters, hora limite

@type function
/*/
User Function TRETE007(cEmp,cFil,cDataLimite,cHoraLimite)

Local cIdAbastecimento 	:= "1" // Id da biblioteca de comunicação com a concentradora para leitura de abastecimentos
Local cUser := '000000'
Default cDataLimite		:= ""
Default cHoraLimite		:= "" 

Conout(" ############ INICIO DO JOB PARA LEITURA DE ABASTECIMENTOS ############# ")

RpcSetType(3) // Para nao consumir licenças na Threads
//Reset Environment
lConect := RpcSetEnv(cEmp, cFil, , ,'FRT',)
__CUSERID := cUser

SET DATE FORMAT TO "dd/mm/yyyy"
SET CENTURY ON
SET DATE BRITISH

if lConect
	Conout(">> EMPRESA: " + cEmp)
	Conout(">> FILIAL: " + cFil)
else
	Conout(">> NAO FOI POSSIVEL CONECTAR NA EMPRESA " + cEmp + " FILIAL " + cFil)
	Return()
endif

// faço um loop na tabela de concentradoras
MHX->(DbSetOrder(1)) //MHX_FILIAL+MHX_CODCON
MHX->(DbGoTop())
if MHX->(DbSeek(xFilial("MHX")))
	
	while MHX->(!EOF()) .and. MHX->MHX_FILIAL == xFilial("MHX")
		
		if MHX->MHX_STATUS <> "2"
			// faço a leitura dos abastecimentos
			U_TRETE001(MHX->MHX_CODCON,cIdAbastecimento,{cDataLimite,cHoraLimite})
		endif
		
		MHX->(DbSkip())
		
	enddo
	
else	
	Conout(">> NAO EXISTEM CONCENTRADORAS CADASTRADAS" )	
endif

Conout(" ############## FIM DO JOB PARA LEITURA DE ABASTECIMENTOS ############## ")

Return()

/*
Função para ser chamada do TRETE022
Obs.: Funciona apenas para CBC e NÃO funciona para FUSION

Ex.:

;JOB DE LEITURA DE ABASTECIMENTOS DA CONCENTRADORA
[U_TRETE07A]
Main=U_TRETE022
Environment=HOSTS
nParms=4
Parm1=TRETE07A
Parm2=01
Parm3=0101
Parm4=2000
*/
User Function TRETE07A()

Local cIdAbastecimento 	:= "1" // Id da biblioteca de comunicação com a concentradora para leitura de abastecimentos
Local cDataLimite		:= ""
Local cHoraLimite		:= "" 

Conout(" ############ INICIO DO JOB PARA LEITURA DE ABASTECIMENTOS ############# ")

// faço um loop na tabela de concentradoras
MHX->(DbSetOrder(1)) //MHX_FILIAL+MHX_CODCON
MHX->(DbGoTop())
If MHX->(DbSeek(xFilial("MHX")))	
	While MHX->(!EOF()) .and. MHX->MHX_FILIAL == xFilial("MHX")
		If MHX->MHX_STATUS <> "2"
			// faço a leitura dos abastecimentos
			U_TRETE001(MHX->MHX_CODCON,cIdAbastecimento,{cDataLimite,cHoraLimite})
		EndIf
		MHX->(DbSkip())	
	EndDo
Else	
	Conout(">> NAO EXISTEM CONCENTRADORAS CADASTRADAS" )	
EndIf

Conout(" ############## FIM DO JOB PARA LEITURA DE ABASTECIMENTOS ############## ")

Return()
