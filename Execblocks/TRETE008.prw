#INCLUDE "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} TRETE008
Importação Volumetria de Tanque (ZE6 e ZE7).

@author Totvs TBC
@since 21/10/2013
@version 1.0
@return ${return}, ${return_description}

@obs
Formato arquivo xls ou xlsx a ser importado: [MEDIDA];[VOLUME]
Ex.: teste.xls
1,00;6,00;
2,00;18,00;
3,00;33,00;

@type function
/*/
User Function TRETE008()
Local cArq := ""
Local cArq2 := ""
Local aArea	:= GetArea()

cArq := AllTrim(cGetFile("Arquivo xls(*.xls)|*.xls|Arquivo xlsx(*.xlsx)|*.xlsx ",;
	"Selecione a pasta e nome do arquivo",,,.T.,,.F.))

if empty(cArq)
	Return
else
	Processa({|| xItVol(cArq) },cArq)
endif 
RestArea(aArea)
Return()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³DOIMPXLS  ºAutor  ³Jonatas Souza       º Data ³  09/12/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Gera layout para importacao da folha                       º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function xItVol(cArquivo) //cArquivo := "C:/temp/arquivo.xls"
Local aDados := {}
Local oXls2Csv
Local nX 
Local nPosExt := RAT(".", cArquivo)-1
Local cFilVol := ZE6->ZE6_FILIAL
Local cCodigo := ZE6->ZE6_TABELA
Local cVolume := ""
Local cMedida := "" 
Local nMedida := 0.00
Local nSeq := 0 
Local cQry:= " "   

if nPosExt < 1
	Return
endif
//Deleta itens
BEGIN TRANSACTION
	cQry:= " DELETE
	cQry+= " FROM "+RetSQLName("ZE7")
	cQry+= " WHERE D_E_L_E_T_ <> '*'
	cQry+= " AND ZE7_FILIAL = '"+cFilVol+"'
	cQry+= " AND ZE7_CODIGO = '"+cCodigo+"'
	If tcsqlexec(cQry) < 0
		MsgStop(tcsqlerror()+' '+cQry)
	Endif
END TRANSACTION
DBSELECTAREA("ZE7")
ZE7->(DBSETORDER(1))             
//cria objeto
oXls2Csv := XLS2CSV():New( cArquivo )
               
if oXls2Csv:Import() //processa importação dos dados, gerando arquivo CSV
	aDados := oXls2Csv:GetArray(0) //transforma arquivo CSV em array. O parâmetro é a partir de qual linha irá considerar os dados                              
	if len(aDados) > 0 
		procregua(0)                             
		For nX := 1 to len(aDados)
			cVolume := StrTran(aDados[nX,2],",",".")
			cMedida := StrTran(aDados[nX,1],",",".")
			nMedida := Round(val(cMedida),2)
			
			nSeq++
			incproc("Itens importados: "+strzero(nSeq,4))
			RecLock("ZE7",.T.)
			Replace ZE7_FILIAL         	With cFilVol
			Replace ZE7_CODIGO         	With cCodigo
			Replace ZE7_ITEM      		With strzero(nSeq,4)
			Replace ZE7_MEDIDA	       	With nMedida
			Replace ZE7_VOLUME	       	With Round(val(cVolume),2)
   			MsUnlock()                                                         
		next nX 

		MsgAlert("Processo finalizado.","Atencao!")
	else
		MsgAlert("O arquivo de nome "+cArquivo+" nao está estruturado dentro dos conforme!. Verifique também se o arquivo XLS2DBF.XLA se encontra na SYSTEM","Atencao!")
		Return()
	endif
else
	Return()          
endif           
oXls2Csv:Destroy() //limpla objeto e exclui arquivo CSV gerado na pasta temp

Return